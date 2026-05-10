import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class AddTaskPage extends StatefulWidget {
  final UserModel user;
  const AddTaskPage({super.key, required this.user});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey               = GlobalKey<FormState>();
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();

  String?   _selectedPriority;
  dynamic   _selectedEvent;
  DateTime? _selectedDeadline;

  List<dynamic> _events = [];
  bool _isLoadingEvents = true;
  bool _isSaving        = false;

  final List<Map<String, dynamic>> _priorities = [
    {'label': 'LOW',    'color': Colors.green, 'icon': Icons.keyboard_double_arrow_down},
    {'label': 'MEDIUM', 'color': Colors.orange,'icon': Icons.drag_handle},
    {'label': 'HIGH',   'color': Colors.red,   'icon': Icons.keyboard_double_arrow_up},
  ];

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
        _events          = data;
        _isLoadingEvents = false;
        if (_events.length == 1) _selectedEvent = _events[0];
      });
    } catch (e) {
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  String _formatDate(DateTime dt) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${dt.day} ${m[dt.month]} ${dt.year}";
  }

  String _toApiDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an event"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a priority"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a deadline"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.addTask({
        "title":       _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "priority":    _selectedPriority,
        "deadline":    _toApiDate(_selectedDeadline!),
        "eventId":     _selectedEvent["id"],
      });
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task added!"), backgroundColor: Colors.green));
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedPriority = null;
      _selectedDeadline = null;
      if (_events.length != 1) _selectedEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (_isLoadingEvents) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Task', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Create a new task for your event', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Linked Event ─────────────────────────────────────
                        _label(context, 'Linked Event', Icons.event_outlined, required: true),
                        const SizedBox(height: 8),
                        _events.isEmpty
                            ? _warningBox(context, 'No events found.')
                            : DropdownButtonFormField<dynamic>(
                                value: _selectedEvent,
                                isExpanded: true,
                                decoration: _inputDeco('Select event', Icons.event_outlined),
                                items: _events.map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedEvent = val),
                                validator: (_) => _selectedEvent == null ? 'Select an event' : null,
                              ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        // ── Title ────────────────────────────────────────────
                        _label(context, 'Task Title', Icons.title, required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('e.g. Book the photographer', Icons.title),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        ),

                        const SizedBox(height: 16),

                        // ── Priority ─────────────────────────────────────────
                        _label(context, 'Priority', Icons.flag_outlined, required: true),
                        const SizedBox(height: 10),
                        Row(
                          children: _priorities.map((p) {
                            final isSelected = _selectedPriority == p['label'];
                            final color      = p['color'] as Color;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: p['label'] != 'HIGH' ? 8 : 0),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedPriority = p['label']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color : color.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2 : 1),
                                    ),
                                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(p['icon'] as IconData, size: 20, color: isSelected ? Colors.white : color),
                                      const SizedBox(height: 4),
                                      Text(p['label'] as String,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                              color: isSelected ? Colors.white : color)),
                                    ]),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // ── Deadline ─────────────────────────────────────────
                        _label(context, 'Deadline', Icons.calendar_today_outlined, required: true),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDeadline,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedDeadline != null
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                  : Colors.transparent,
                              border: Border.all(
                                color: _selectedDeadline != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: _selectedDeadline != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDeadline != null
                                      ? _formatDate(_selectedDeadline!)
                                      : 'Select deadline date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDeadline != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Description ──────────────────────────────────────
                        _label(context, 'Description', Icons.description_outlined),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('Add task notes or instructions...', Icons.description_outlined)
                              .copyWith(alignLabelWithHint: true),
                        ),

                        const SizedBox(height: 32),

                        // ── Buttons ──────────────────────────────────────────
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton.icon(
                            onPressed: (_isSaving || _events.isEmpty) ? null : _handleSubmit,
                            icon: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.add_task, size: 20),
                            label: Text(_isSaving ? 'Adding Task...' : 'Add Task',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _resetForm,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset Form'),
                            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String label, IconData icon, {bool required = false}) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      if (required) ...[const SizedBox(width: 4), Text('*', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))],
    ]);
  }

  Widget _warningBox(BuildContext context, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Text(msg, style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}