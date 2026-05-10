import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class AddGuestPage extends StatefulWidget {
  final UserModel user;

  const AddGuestPage({super.key, required this.user});

  @override
  State<AddGuestPage> createState() => _AddGuestPageState();
}

class _AddGuestPageState extends State<AddGuestPage> {
  final _formKey             = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _emailController     = TextEditingController();
  final _mobileController    = TextEditingController();
  final _addressController   = TextEditingController();
  final _relationController  = TextEditingController();

  String? _selectedGender;
  dynamic _selectedEvent;
  List<dynamic> _events = [];

  bool _isLoadingEvents = true;
  bool _isSaving        = false;

  final List<String> _genderOptions   = ['Male', 'Female'];
  final List<String> _relationOptions = [
    'Family',
    'Friend',
    'Colleague',
    'Relative',
    'Neighbor',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ApiService.getUserEvents(widget.user.id);
      setState(() {
        _events          = data;
        _isLoadingEvents = false;
        // Auto-select if only one event
        if (_events.length == 1) _selectedEvent = _events[0];
      });
    } catch (e) {
      setState(() => _isLoadingEvents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load events: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleAddGuest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select an event"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select gender"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.addGuest({
        "name":     _nameController.text.trim(),
        "email":    _emailController.text.trim(),
        "mobile":   _mobileController.text.trim(),
        "address":  _addressController.text.trim(),
        "relation": _relationController.text.trim(),
        "gender":   _selectedGender!.toUpperCase(),
        "eventId":  _selectedEvent["id"],
      });

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Guest added successfully!"),
              backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to add guest: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _addressController.clear();
    _relationController.clear();
    setState(() {
      _selectedGender = null;
      if (_events.length != 1) _selectedEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return _isLoadingEvents
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ─────────────────────────────────────────────
                      Text('Add Guest',
                          style:
                              Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                          'Fill in guest details. RSVP starts as Pending and updates automatically when the guest responds via email.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 32),

                      // ── Form Card ──────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // ── Linked Event ────────────────────────────────
                              _buildLabel(context, 'Linked Event',
                                  Icons.event_outlined, required: true),
                              const SizedBox(height: 8),
                              _events.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.orange
                                                .withOpacity(0.3)),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.warning_amber,
                                            color: Colors.orange, size: 18),
                                        const SizedBox(width: 10),
                                        Text(
                                          'No events found. Please create an event first.',
                                          style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontSize: 13),
                                        ),
                                      ]),
                                    )
                                  : DropdownButtonFormField<dynamic>(
                                      value: _selectedEvent,
                                      decoration: _inputDecoration(
                                          'Select event',
                                          Icons.event_outlined),
                                      items: _events
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  "${e["name"]} — ${e["eventDate"] ?? ""}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedEvent = val),
                                      validator: (_) => _selectedEvent == null
                                          ? 'Please select an event'
                                          : null,
                                    ),

                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 20),

                              // ── Name ────────────────────────────────────────
                              _buildLabel(context, 'Full Name',
                                  Icons.person_outline,
                                  required: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: _inputDecoration(
                                    'Enter guest name',
                                    Icons.person_outline),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),

                              const SizedBox(height: 16),

                              // ── Email ────────────────────────────────────────
                              _buildLabel(context, 'Email',
                                  Icons.email_outlined,
                                  required: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                    'Enter email for RSVP link',
                                    Icons.email_outlined),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required for RSVP';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // ── Mobile ───────────────────────────────────────
                              _buildLabel(context, 'Phone Number',
                                  Icons.phone_outlined),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: _inputDecoration(
                                    'Enter 10-digit mobile number',
                                    Icons.phone_outlined),
                                validator: (v) {
                                  if (v != null &&
                                      v.isNotEmpty &&
                                      v.length != 10) {
                                    return 'Enter valid 10-digit number';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // ── Gender ───────────────────────────────────────
                              _buildLabel(context, 'Gender',
                                  Icons.wc_outlined,
                                  required: true),
                              const SizedBox(height: 8),
                              Row(
                                children: _genderOptions.map((gender) {
                                  final isSelected =
                                      _selectedGender == gender;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: gender == 'Male' ? 8 : 0),
                                      child: InkWell(
                                        onTap: () => setState(
                                            () => _selectedGender = gender),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.2),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                gender == 'Male'
                                                    ? Icons.male
                                                    : Icons.female,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                gender,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16),

                              // ── Relation ─────────────────────────────────────
                              _buildLabel(context, 'Relation',
                                  Icons.people_outline),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _relationController.text.isEmpty
                                    ? null
                                    : _relationController.text,
                                decoration: _inputDecoration(
                                    'Select relation',
                                    Icons.people_outline),
                                items: _relationOptions
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _relationController.text = val;
                                  }
                                },
                              ),

                              const SizedBox(height: 16),

                              // ── Address ──────────────────────────────────────
                              _buildLabel(context, 'Address',
                                  Icons.home_outlined),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _inputDecoration(
                                        'Enter address', Icons.home_outlined)
                                    .copyWith(
                                        alignLabelWithHint: true),
                              ),

                              const SizedBox(height: 16),

                              // ── RSVP Status (read-only badge) ─────────────────
                              _buildLabel(context, 'RSVP Status',
                                  Icons.mark_email_read_outlined),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_empty,
                                        color: Colors.orange, size: 18),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'PENDING',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '— Auto-updated when guest responds via email',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Submit ────────────────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: (_isSaving || _events.isEmpty)
                                      ? null
                                      : _handleAddGuest,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Icon(
                                          Icons.person_add_outlined,
                                          size: 20),
                                  label: Text(
                                    _isSaving
                                        ? 'Adding Guest...'
                                        : 'Add Guest',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Reset ─────────────────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _resetForm,
                                  icon:
                                      const Icon(Icons.refresh, size: 18),
                                  label: const Text('Reset Form'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Info Card ──────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('About RSVP',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(fontSize: 14)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'An RSVP email will be sent to the guest automatically. When they click Accept or Decline in the email, their status updates to CONFIRMED or DECLINED in real time.',
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

  Widget _buildLabel(BuildContext context, String label, IconData icon,
      {bool required = false}) {
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
        if (required) ...[
          const SizedBox(width: 4),
          Text('*',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon,
          color: Theme.of(context).colorScheme.primary, size: 20),
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