import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class CreateEventPage extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onEventCreated; // callback to refresh parent

  const CreateEventPage({
    super.key,
    required this.user,
    this.onEventCreated,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  String _toApiDate(DateTime dt) {
    // Backend expects String — send as yyyy-MM-dd
    final month = dt.month.toString().padLeft(2, '0');
    final day   = dt.day.toString().padLeft(2, '0');
    return "${dt.year}-$month-$day";
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an event date"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.createEvent({
        "name":      _nameController.text.trim(),
        "eventDate": _toApiDate(_selectedDate!),
        "location":  _locationController.text.trim(),
      });

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Event created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _nameController.clear();
        _locationController.clear();
        setState(() => _selectedDate = null);

        // Notify parent to refresh if callback provided
        widget.onEventCreated?.call();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create event: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // ── No Scaffold — embeds inline in dashboard ──────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isMobile ? double.infinity : 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Page Header ───────────────────────────────────────────────
                Text('Create Event',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Fill in the details to create a new wedding event',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                // ── Form Card ─────────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Event Name ─────────────────────────────────────────
                        _buildLabel(context, 'Event Name', Icons.celebration_outlined),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'e.g. Sharma Wedding Ceremony',
                            Icons.celebration_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Event name is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // ── Event Date ─────────────────────────────────────────
                        _buildLabel(context, 'Event Date', Icons.calendar_today_outlined),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedDate != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2),
                                width: _selectedDate != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedDate != null
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? _formatDate(_selectedDate!)
                                        : 'Select event date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Location ───────────────────────────────────────────
                        _buildLabel(context, 'Location', Icons.location_on_outlined),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'e.g. Taj Palace, New Delhi',
                            Icons.location_on_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Location is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // ── Submit Button ──────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleCreate,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle_outline,
                                    size: 20),
                            label: Text(
                              _isSaving ? 'Creating...' : 'Create Event',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Reset Button ───────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    _formKey.currentState?.reset();
                                    _nameController.clear();
                                    _locationController.clear();
                                    setState(() => _selectedDate = null);
                                  },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset Form'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Info Card ─────────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('What happens next?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                'After creating the event you can add guests, manage budget, assign vendors and track tasks — all from the sidebar navigation.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.5),
                              ),
                            ],
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildLabel(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            )),
        const SizedBox(width: 4),
        Text('*',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color:
                Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
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