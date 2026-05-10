import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class AllTasksPage extends StatefulWidget {
  final UserModel user;
  const AllTasksPage({super.key, required this.user});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> events   = [];
  List<dynamic> allTasks = [];
  dynamic selectedEvent;

  bool isLoadingEvents = true;
  bool isLoadingTasks  = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    setState(() { selectedEvent = event; isLoadingTasks = true; allTasks = []; });
    try {
      final data = await ApiService.getTasks(eventId: event["id"].toString());
      setState(() { allTasks = data; isLoadingTasks = false; });
    } catch (e) {
      setState(() => isLoadingTasks = false);
    }
  }

  Future<void> _refresh() async {
    if (selectedEvent == null) return;
    await _selectEvent(selectedEvent);
  }

  List<dynamic> _filtered(String status) {
    if (status == 'ALL') return allTasks;
    return allTasks.where((t) =>
        (t["status"] ?? "").toUpperCase() == status.toUpperCase()).toList();
  }

  int _count(String status) => status == 'ALL'
      ? allTasks.length
      : allTasks.where((t) => (t["status"] ?? "").toUpperCase() == status).length;

  // ── Status helpers ────────────────────────────────────────────────────────────
  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'COMPLETED':   return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      default:            return Colors.orange;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s?.toUpperCase()) {
      case 'COMPLETED':   return Icons.check_circle;
      case 'IN_PROGRESS': return Icons.timelapse;
      default:            return Icons.radio_button_unchecked;
    }
  }

  // ── Priority helpers ──────────────────────────────────────────────────────────
  Color _priorityColor(String? p) {
    switch (p?.toUpperCase()) {
      case 'HIGH':   return Colors.red;
      case 'MEDIUM': return Colors.orange;
      default:       return Colors.green;
    }
  }

  IconData _priorityIcon(String? p) {
    switch (p?.toUpperCase()) {
      case 'HIGH':   return Icons.keyboard_double_arrow_up;
      case 'MEDIUM': return Icons.drag_handle;
      default:       return Icons.keyboard_double_arrow_down;
    }
  }

  // ── Deadline helpers ──────────────────────────────────────────────────────────
  Color _deadlineColor(String? raw) {
    if (raw == null) return Colors.grey;
    try {
      final deadline = DateTime.parse(raw);
      final today    = DateTime.now();
      final diff     = deadline.difference(today).inDays;
      if (diff < 0)  return Colors.red;
      if (diff <= 2) return Colors.orange;
      return Colors.green;
    } catch (_) { return Colors.grey; }
  }

  String _deadlineLabel(String? raw) {
    if (raw == null) return "No deadline";
    try {
      final deadline = DateTime.parse(raw);
      final today    = DateTime.now();
      final diff     = deadline.difference(today).inDays;
      if (diff < 0)  return "Overdue by ${(-diff)} day${-diff == 1 ? '' : 's'}";
      if (diff == 0) return "Due today";
      if (diff == 1) return "Due tomorrow";
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${deadline.day} ${m[deadline.month]}";
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Tasks', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Track and manage all your tasks', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),

              // Event selector
              events.isEmpty
                  ? _warningBox(context, 'No events found. Create an event first.')
                  : DropdownButtonFormField<dynamic>(
                      value: selectedEvent,
                      isExpanded: true,
                      decoration: _inputDeco('Select event to filter tasks', Icons.event_outlined),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All events')),
                        ...events.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => val != null ? _selectEvent(val) : setState(() { selectedEvent = null; allTasks = []; }),
                    ),
            ],
          ),
        ),

        // ── Summary chips ────────────────────────────────────────────────────
        if (allTasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _summaryChip(context, '${allTasks.length}', 'Total', Colors.blue),
              const SizedBox(width: 8),
              _summaryChip(context, '${_count("COMPLETED")}', 'Done', Colors.green),
              const SizedBox(width: 8),
              _summaryChip(context, '${_count("IN_PROGRESS")}', 'In Progress', Colors.blue),
              const SizedBox(width: 8),
              _summaryChip(context, '${_count("PENDING")}', 'Pending', Colors.orange),
            ]),
          ),

        const SizedBox(height: 12),

        // ── Tabs ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.start,
            tabs: [
              _tab(context, 'All',         _count('ALL'),         Colors.blue),
              _tab(context, 'Pending',      _count('PENDING'),     Colors.orange),
              _tab(context, 'In Progress',  _count('IN_PROGRESS'), Colors.blue),
              _tab(context, 'Completed',    _count('COMPLETED'),   Colors.green),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Tab content ───────────────────────────────────────────────────────
        Expanded(
          child: isLoadingTasks
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(context, _filtered('ALL')),
                    _buildTaskList(context, _filtered('PENDING')),
                    _buildTaskList(context, _filtered('IN_PROGRESS')),
                    _buildTaskList(context, _filtered('COMPLETED')),
                  ],
                ),
        ),
      ],
    );
  }

  Tab _tab(BuildContext context, String label, int count, Color color) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildTaskList(BuildContext context, List<dynamic> tasks) {
    if (selectedEvent == null) {
      return _emptyState(context, Icons.event_outlined, 'Select an event to view tasks');
    }
    if (tasks.isEmpty) {
      return _emptyState(context, Icons.task_outlined, 'No tasks in this category');
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildTaskCard(context, tasks[i]),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final status   = task["status"]   ?? "PENDING";
    final priority = task["priority"] ?? "LOW";
    final sColor   = _statusColor(status);
    final pColor   = _priorityColor(priority);
    final dColor   = _deadlineColor(task["deadline"]);
    final isDone   = status.toUpperCase() == 'COMPLETED';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // handled by parent navigation
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status icon
                  GestureDetector(
                    onTap: () => _toggleStatus(task),
                    child: Icon(_statusIcon(status), color: sColor, size: 22),
                  ),
                  const SizedBox(width: 10),

                  // Title
                  Expanded(
                    child: Text(
                      task["title"] ?? "—",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                            : null,
                      ),
                    ),
                  ),

                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: pColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_priorityIcon(priority), size: 12, color: pColor),
                      const SizedBox(width: 3),
                      Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pColor)),
                    ]),
                  ),
                ],
              ),

              // Description
              if (task["description"] != null && (task["description"] as String).isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    task["description"],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Footer row
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(children: [
                  // Deadline
                  Icon(Icons.calendar_today, size: 12, color: dColor),
                  const SizedBox(width: 4),
                  Text(
                    _deadlineLabel(task["deadline"]),
                    style: TextStyle(fontSize: 12, color: dColor, fontWeight: FontWeight.w600),
                  ),

                  // Vendor
                  if (task["vendorName"] != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.store_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(task["vendorName"], style: Theme.of(context).textTheme.bodySmall),
                  ],

                  const Spacer(),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sColor),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> task) async {
    final current = (task["status"] ?? "PENDING").toUpperCase();
    final next    = current == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
    try {
      final updated = await ApiService.updateTask(task["id"].toString(), {"status": next});
      setState(() {
        final idx = allTasks.indexWhere((t) => t["id"] == task["id"]);
        if (idx != -1) allTasks[idx] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _summaryChip(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _warningBox(BuildContext context, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(color: Colors.orange.shade800, fontSize: 13))),
      ]),
    );
  }

  Widget _emptyState(BuildContext context, IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
      const SizedBox(height: 16),
      Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
    ]));
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}