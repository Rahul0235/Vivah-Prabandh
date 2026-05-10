import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final UserModel user;
  const TaskDetailsPage({super.key, required this.user});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  List<dynamic> events         = [];
  List<dynamic> tasks          = [];
  Map<String, dynamic>? selectedTask;
  dynamic selectedEvent;

  bool isLoadingEvents  = true;
  bool isLoadingTasks   = false;
  bool isLoadingDetails = false;
  bool isEditing        = false;
  bool isSaving         = false;

  // Edit controllers
  final _formKey               = GlobalKey<FormState>();
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _editStatus;
  String? _editPriority;
  DateTime? _editDeadline;

  final List<String> _statusOptions   = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];
  final List<String> _priorityOptions = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ApiService.getUserEvents(widget.user.id);
      setState(() {
        events          = data;
        isLoadingEvents = false;
        if (events.length == 1) _selectEvent(events[0]);
      });
    } catch (e) {
      setState(() => isLoadingEvents = false);
    }
  }

  Future<void> _selectEvent(dynamic event) async {
    setState(() { selectedEvent = event; tasks = []; selectedTask = null; isLoadingTasks = true; });
    try {
      final data = await ApiService.getTasks(eventId: event["id"].toString());
      setState(() { tasks = data; isLoadingTasks = false; });
    } catch (e) {
      setState(() => isLoadingTasks = false);
    }
  }

  Future<void> _selectTask(dynamic task) async {
    setState(() { isLoadingDetails = true; isEditing = false; });
    try {
      final data = await ApiService.getTaskById(task["id"].toString());
      setState(() {
        selectedTask    = data;
        isLoadingDetails = false;
        _populateControllers(data);
      });
    } catch (e) {
      setState(() => isLoadingDetails = false);
    }
  }

  void _populateControllers(Map<String, dynamic> t) {
    _titleController.text       = t["title"]       ?? "";
    _descriptionController.text = t["description"] ?? "";
    _editStatus   = t["status"]   ?? "PENDING";
    _editPriority = t["priority"] ?? "LOW";
    if (t["deadline"] != null) {
      try { _editDeadline = DateTime.parse(t["deadline"]); } catch (_) {}
    } else {
      _editDeadline = null;
    }
  }

  void _cancelEdit() {
    setState(() { isEditing = false; _populateControllers(selectedTask!); });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final payload = {
        "title":       _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "status":      _editStatus,
        "priority":    _editPriority,
        if (_editDeadline != null) "deadline": _toApiDate(_editDeadline!),
      };
      final updated = await ApiService.updateTask(selectedTask!["id"].toString(), payload);
      setState(() {
        selectedTask = updated;
        isEditing    = false;
        isSaving     = false;
        _populateControllers(updated);
        final idx = tasks.indexWhere((t) => t["id"] == updated["id"]);
        if (idx != -1) tasks[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task updated!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _quickStatusChange(String newStatus) async {
    try {
      final updated = await ApiService.updateTask(selectedTask!["id"].toString(), {"status": newStatus});
      setState(() {
        selectedTask = updated;
        _populateControllers(updated);
        final idx = tasks.indexWhere((t) => t["id"] == updated["id"]);
        if (idx != -1) tasks[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Marked as ${newStatus.replaceAll('_', ' ')}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDeadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _editDeadline = picked);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _toApiDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";

  String _fmtDate(dynamic raw) {
    if (raw == null) return "—";
    try {
      final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${dt.day} ${m[dt.month]} ${dt.year}";
    } catch (_) { return raw.toString(); }
  }

  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'COMPLETED':   return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      default:            return Colors.orange;
    }
  }

  Color _priorityColor(String? p) {
    switch (p?.toUpperCase()) {
      case 'HIGH':   return Colors.red;
      case 'MEDIUM': return Colors.orange;
      default:       return Colors.green;
    }
  }

  Color _deadlineColor(dynamic raw) {
    if (raw == null) return Colors.grey;
    try {
      final diff = DateTime.parse(raw.toString()).difference(DateTime.now()).inDays;
      if (diff < 0)  return Colors.red;
      if (diff <= 2) return Colors.orange;
      return Colors.green;
    } catch (_) { return Colors.grey; }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());
    return isMobile ? _buildMobileLayout(context) : _buildWebLayout(context);
  }

  // ── Mobile: 3-step drill-down ─────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    if (selectedTask != null) {
      return Column(children: [
        _detailHeader(context, isMobile: true),
        const Divider(height: 1),
        Expanded(child: isLoadingDetails ? const Center(child: CircularProgressIndicator()) : _buildDetailsContent(context)),
      ]);
    }
    if (selectedEvent != null) {
      return Column(children: [
        _taskListHeader(context),
        const Divider(height: 1),
        Expanded(child: _buildTaskList(context)),
      ]);
    }
    return _buildEventSelector(context);
  }

  // ── Web: 3-column split ───────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    return Row(children: [
      // Col 1 — events
      Container(
        width: 220,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)))),
        child: _buildEventSelector(context),
      ),
      // Col 2 — tasks
      Container(
        width: 260,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)))),
        child: selectedEvent == null
            ? _centerPrompt(context, Icons.event_outlined, 'Select an event')
            : Column(children: [_taskListHeader(context), const Divider(height: 1), Expanded(child: _buildTaskList(context))]),
      ),
      // Col 3 — details
      Expanded(
        child: selectedTask == null
            ? _centerPrompt(context, Icons.task_outlined, 'Select a task to view details')
            : isLoadingDetails
                ? const Center(child: CircularProgressIndicator())
                : Column(children: [_detailHeader(context, isMobile: false), const Divider(height: 1), Expanded(child: _buildDetailsContent(context))]),
      ),
    ]);
  }

  // ── Event selector ────────────────────────────────────────────────────────────

  Widget _buildEventSelector(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Task Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Select event then task', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
      const Divider(height: 1),
      events.isEmpty
          ? Expanded(child: _centerPrompt(context, Icons.event_busy, 'No events found'))
          : Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = events[i];
                  final isSel = selectedEvent?["id"] == e["id"];
                  return InkWell(
                    onTap: () => _selectEvent(e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSel ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.1), width: isSel ? 2 : 1),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e["name"] ?? "—", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSel ? Theme.of(context).colorScheme.primary : null)),
                        const SizedBox(height: 3),
                        Text(e["eventDate"] ?? "—", style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                  );
                },
              ),
            ),
    ]);
  }

  // ── Task list ─────────────────────────────────────────────────────────────────

  Widget _taskListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(children: [
        if (selectedTask != null && MediaQuery.of(context).size.width < 768)
          GestureDetector(onTap: () => setState(() => selectedTask = null), child: Icon(Icons.arrow_back, size: 20, color: Theme.of(context).colorScheme.primary)),
        if (selectedTask != null && MediaQuery.of(context).size.width < 768) const SizedBox(width: 8),
        Expanded(child: Text(selectedEvent?["name"] ?? "Tasks", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        Text('${tasks.length}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    if (isLoadingTasks) return const Center(child: CircularProgressIndicator());
    if (tasks.isEmpty) return _centerPrompt(context, Icons.task_outlined, 'No tasks for this event');

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t     = tasks[i];
        final isSel = selectedTask?["id"] == t["id"];
        final sColor = _statusColor(t["status"]);
        final pColor = _priorityColor(t["priority"]);

        return InkWell(
          onTap: () => _selectTask(t),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSel ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.1), width: isSel ? 2 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t["title"] ?? "—", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(t["priority"] ?? "—", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: pColor))),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text((t["status"] ?? "—").toString().replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sColor))),
              ]),
            ]),
          ),
        );
      },
    );
  }

  // ── Detail header bar ─────────────────────────────────────────────────────────

  Widget _detailHeader(BuildContext context, {required bool isMobile}) {
    final status = selectedTask?["status"] ?? "PENDING";
    final isDone = status.toUpperCase() == 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        if (isMobile) ...[
          IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary), onPressed: () => setState(() => selectedTask = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(selectedTask?["title"] ?? "Task Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        if (!isEditing) ...[
          // Quick complete / pending toggle
          if (!isDone)
            TextButton.icon(
              onPressed: () => _quickStatusChange('COMPLETED'),
              icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
              label: const Text('Complete', style: TextStyle(color: Colors.green, fontSize: 12)),
            )
          else
            TextButton.icon(
              onPressed: () => _quickStatusChange('PENDING'),
              icon: Icon(Icons.undo, size: 16, color: Theme.of(context).colorScheme.primary),
              label: Text('Mark Pending', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
            ),
          TextButton.icon(
            onPressed: () => setState(() => isEditing = true),
            icon: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
            label: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ] else ...[
          TextButton(onPressed: isSaving ? null : _cancelEdit, child: const Text('Cancel', style: TextStyle(fontSize: 12))),
          ElevatedButton(
            onPressed: isSaving ? null : _saveTask,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontSize: 12)),
          ),
        ],
      ]),
    );
  }

  // ── Details content ───────────────────────────────────────────────────────────

  Widget _buildDetailsContent(BuildContext context) {
    final t        = selectedTask!;
    final status   = t["status"]   ?? "PENDING";
    final priority = t["priority"] ?? "LOW";
    final sColor   = _statusColor(status);
    final pColor   = _priorityColor(priority);
    final dColor   = _deadlineColor(t["deadline"]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status + Priority row ───────────────────────────────────────
          Row(children: [
            // Status
            isEditing
                ? Expanded(child: DropdownButtonFormField<String>(
                    value: _editStatus,
                    decoration: _inputDecoSm('Status', Icons.radio_button_checked),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s,
                        child: Row(children: [
                          Icon(Icons.circle, size: 8, color: _statusColor(s)),
                          const SizedBox(width: 6),
                          Text(s.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)),
                        ]))).toList(),
                    onChanged: (val) => setState(() => _editStatus = val),
                  ))
                : _badgeChip(context, status.replaceAll('_', ' '), sColor),

            const SizedBox(width: 10),

            // Priority
            isEditing
                ? Expanded(child: DropdownButtonFormField<String>(
                    value: _editPriority,
                    decoration: _inputDecoSm('Priority', Icons.flag_outlined),
                    items: _priorityOptions.map((p) => DropdownMenuItem(value: p,
                        child: Row(children: [
                          Icon(Icons.circle, size: 8, color: _priorityColor(p)),
                          const SizedBox(width: 6),
                          Text(p, style: const TextStyle(fontSize: 13)),
                        ]))).toList(),
                    onChanged: (val) => setState(() => _editPriority = val),
                  ))
                : _badgeChip(context, priority, pColor),
          ]),

          const SizedBox(height: 20),

          // ── Task info card ─────────────────────────────────────────────
          _sectionHeader(context, 'Task Information', Icons.task_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Title
                isEditing
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel(context, 'Title', Icons.title),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDeco('Task title', Icons.title),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ])
                    : _infoRow(context, Icons.title, 'Title', t["title"] ?? "—"),

                const SizedBox(height: 14),

                // Deadline
                isEditing
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel(context, 'Deadline', Icons.calendar_today_outlined),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDeadline,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: _editDeadline != null ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.transparent,
                              border: Border.all(color: _editDeadline != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.2), width: _editDeadline != null ? 2 : 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(_editDeadline != null ? _fmtDate(_editDeadline) : 'Select deadline',
                                  style: TextStyle(color: _editDeadline != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                            ]),
                          ),
                        ),
                      ])
                    : _infoRow(context, Icons.calendar_today_outlined, 'Deadline', _fmtDate(t["deadline"]),
                        valueColor: dColor),

                const SizedBox(height: 14),

                // Event
                _infoRow(context, Icons.event_outlined, 'Event', t["eventName"] ?? "—"),
                if (t["vendorName"] != null) ...[
                  const SizedBox(height: 14),
                  _infoRow(context, Icons.store_outlined, 'Assigned Vendor', t["vendorName"]),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── Description / Notes card ───────────────────────────────────
          _sectionHeader(context, 'Description & Notes', Icons.notes_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isEditing
                  ? TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: _inputDeco('Add notes or instructions...', Icons.notes_outlined)
                          .copyWith(alignLabelWithHint: true),
                    )
                  : (t["description"] != null && (t["description"] as String).isNotEmpty)
                      ? Text(t["description"], style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6))
                      : Text('No description added.', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35), fontStyle: FontStyle.italic)),
            ),
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _badgeChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
      ])),
    ]);
  }

  Widget _fieldLabel(BuildContext context, String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _centerPrompt(BuildContext context, IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
      const SizedBox(height: 12),
      Text(message, style: Theme.of(context).textTheme.bodySmall),
    ]));
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
    );
  }

  InputDecoration _inputDecoSm(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}