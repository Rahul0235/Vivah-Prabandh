import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class AddExpensePage extends StatefulWidget {
  final UserModel user;
  const AddExpensePage({super.key, required this.user});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey             = GlobalKey<FormState>();
  final _amountController    = TextEditingController();
  final _descriptionController = TextEditingController();

  String?  _selectedCategory;
  dynamic  _selectedEvent;
  DateTime? _selectedDate;
  List<dynamic> _events = [];

  bool _isLoadingEvents = true;
  bool _isSaving        = false;

  // ── Category options with icons ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Catering',      'icon': Icons.restaurant_outlined},
    {'label': 'Decoration',    'icon': Icons.celebration_outlined},
    {'label': 'Photography',   'icon': Icons.camera_alt_outlined},
    {'label': 'Videography',   'icon': Icons.videocam_outlined},
    {'label': 'Venue',         'icon': Icons.location_on_outlined},
    {'label': 'Music / DJ',    'icon': Icons.music_note_outlined},
    {'label': 'Makeup',        'icon': Icons.face_retouching_natural},
    {'label': 'Mehendi',       'icon': Icons.palette_outlined},
    {'label': 'Transport',     'icon': Icons.directions_car_outlined},
    {'label': 'Clothing',      'icon': Icons.checkroom_outlined},
    {'label': 'Invitation',    'icon': Icons.mail_outline},
    {'label': 'Other',         'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _amountController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  String _toApiDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "${dt.year}-$m-$d";
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an event"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.addExpense({
        "category":    _selectedCategory,
        "amount":      double.parse(_amountController.text.trim()),
        "description": _descriptionController.text.trim(),
        "date":        _toApiDate(_selectedDate!),
        "eventId":     _selectedEvent["id"],
      });

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense added successfully!"), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add expense: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDate     = null;
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
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────────
                Text('Add Expense', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Record a new expense for your event', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Linked Event ──────────────────────────────────────
                        _label(context, 'Linked Event', Icons.event_outlined, required: true),
                        const SizedBox(height: 8),
                        _events.isEmpty
                            ? _warningBox(context, 'No events found. Create an event first.')
                            : DropdownButtonFormField<dynamic>(
                                value: _selectedEvent,
                                decoration: _inputDeco('Select event', Icons.event_outlined),
                                items: _events.map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedEvent = val),
                                validator: (_) => _selectedEvent == null ? 'Please select an event' : null,
                              ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        // ── Category grid ─────────────────────────────────────
                        _label(context, 'Category', Icons.category_outlined, required: true),
                        const SizedBox(height: 12),
                        LayoutBuilder(builder: (context, constraints) {
                          final cols = constraints.maxWidth > 400 ? 4 : 3;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: cols,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.1,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['label'];
                              return InkWell(
                                onTap: () => setState(() => _selectedCategory = cat['label']),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 22,
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat['label'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.primary,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),

                        const SizedBox(height: 20),

                        // ── Amount ────────────────────────────────────────────
                        _label(context, 'Amount (₹)', Icons.currency_rupee, required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: _inputDeco('Enter amount e.g. 15000', Icons.currency_rupee),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Amount is required';
                            final d = double.tryParse(v.trim());
                            if (d == null || d <= 0) return 'Enter a valid amount';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ── Date ──────────────────────────────────────────────
                        _label(context, 'Date', Icons.calendar_today_outlined, required: true),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedDate != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: _selectedDate != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedDate != null
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate != null ? _formatDate(_selectedDate!) : 'Select expense date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDate != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Description ───────────────────────────────────────
                        _label(context, 'Description', Icons.description_outlined),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('Add notes about this expense...', Icons.description_outlined)
                              .copyWith(alignLabelWithHint: true),
                        ),

                        const SizedBox(height: 32),

                        // ── Submit ────────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: (_isSaving || _events.isEmpty) ? null : _handleSubmit,
                            icon: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.add_circle_outline, size: 20),
                            label: Text(
                              _isSaving ? 'Adding Expense...' : 'Add Expense',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Reset ─────────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _resetForm,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset Form'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Selected summary preview ───────────────────────────────────
                if (_selectedCategory != null || _selectedDate != null ||
                    _amountController.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.receipt_long_outlined,
                                color: Theme.of(context).colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text('Expense Preview',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                          ]),
                          const SizedBox(height: 12),
                          if (_selectedEvent != null)
                            _previewRow(context, 'Event', _selectedEvent["name"] ?? "—"),
                          if (_selectedCategory != null)
                            _previewRow(context, 'Category', _selectedCategory!),
                          if (_amountController.text.isNotEmpty)
                            _previewRow(context, 'Amount', '₹${_amountController.text}'),
                          if (_selectedDate != null)
                            _previewRow(context, 'Date', _formatDate(_selectedDate!)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _label(BuildContext context, String label, IconData icon, {bool required = false}) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      if (required) ...[
        const SizedBox(width: 4),
        Text('*', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      ],
    ]);
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
        Text(msg, style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
      ]),
    );
  }

  Widget _previewRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}