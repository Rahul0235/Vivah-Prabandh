import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class BookVendorPage extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> vendor;
  const BookVendorPage({super.key, required this.user, required this.vendor});

  @override
  State<BookVendorPage> createState() => _BookVendorPageState();
}

class _BookVendorPageState extends State<BookVendorPage> {
  final _formKey              = GlobalKey<FormState>();
  final _userNameController   = TextEditingController();
  final _userContactController= TextEditingController();
  final _locationController   = TextEditingController();
  final _notesController      = TextEditingController();
  final _serviceController    = TextEditingController();

  dynamic   _selectedEvent;
  DateTime? _bookingDate;
  String?   _paymentMethod; // CASH / ONLINE

  List<dynamic> _events = [];
  bool _isLoadingEvents = true;
  bool _isSaving        = false;

  @override
  void initState() {
    super.initState();
    _userNameController.text    = widget.user.name;
    _userContactController.text = widget.user.mobile ?? '';
    _serviceController.text     = widget.vendor["services"] ?? '';
    _loadEvents();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userContactController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _serviceController.dispose();
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
      initialDate: _bookingDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _bookingDate = picked);
  }

  String _fmtDate(DateTime dt) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${dt.day} ${m[dt.month]} ${dt.year}";
  }

  String _toApiDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEvent == null) {
      _snack("Please select an event", Colors.orange);
      return;
    }
    if (_bookingDate == null) {
      _snack("Please select a booking date", Colors.orange);
      return;
    }
    if (_paymentMethod == null) {
      _snack("Please select a payment method", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.bookVendor({
        "vendorId":     widget.vendor["id"],
        "eventId":      _selectedEvent["id"],
        "bookingDate":  _toApiDate(_bookingDate!),
        "service":      _serviceController.text.trim(),
        "paymentMethod":_paymentMethod,
        "notes":        _notesController.text.trim(),
        "userName":     _userNameController.text.trim(),
        "userContact":  _userContactController.text.trim(),
        "eventLocation":_locationController.text.trim(),
      });
      setState(() => _isSaving = false);
      if (mounted) {
        _snack("Booking submitted! Vendor will confirm soon.", Colors.green);
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _snack("Booking failed: $e", Colors.red);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _locationController.clear();
    _notesController.clear();
    setState(() {
      _bookingDate   = null;
      _paymentMethod = null;
      if (_events.length != 1) _selectedEvent = null;
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Book Vendor', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Fill in your booking details', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Vendor summary ─────────────────────────────────────────────
              Card(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.store_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.vendor["name"] ?? "—", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text("${widget.vendor["category"] ?? "—"}  •  ${widget.vendor["location"] ?? "—"}",
                          style: Theme.of(context).textTheme.bodySmall),
                    ])),
                    if (widget.vendor["price"] != null)
                      Text('₹${widget.vendor["price"]}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Linked Event
                    _label(context, 'Linked Event', Icons.event_outlined, required: true),
                    const SizedBox(height: 8),
                    _events.isEmpty
                        ? _warnBox(context, 'No events found.')
                        : DropdownButtonFormField<dynamic>(
                            value: _selectedEvent,
                            isExpanded: true,
                            decoration: _deco('Select event', Icons.event_outlined),
                            items: _events.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedEvent = val),
                            validator: (_) => _selectedEvent == null ? 'Select an event' : null,
                          ),

                    const SizedBox(height: 16),

                    // Booking Date
                    _label(context, 'Booking Date', Icons.calendar_today_outlined, required: true),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: _bookingDate != null ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.transparent,
                          border: Border.all(color: _bookingDate != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.2), width: _bookingDate != null ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _bookingDate != null ? _fmtDate(_bookingDate!) : 'Select date',
                            style: TextStyle(fontSize: 16, color: _bookingDate != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Service
                    _label(context, 'Service Required', Icons.build_outlined, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _serviceController,
                      decoration: _deco('e.g. Full catering for 500 guests', Icons.build_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Service is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Payment Method
                    _label(context, 'Payment Method', Icons.payment_outlined, required: true),
                    const SizedBox(height: 10),
                    Row(children: [
                      _paymentTile(context, 'CASH', Icons.money_outlined, 'Cash on Site'),
                      const SizedBox(width: 10),
                      _paymentTile(context, 'ONLINE', Icons.qr_code_outlined, 'UPI / Online'),
                    ]),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Booker name
                    _label(context, 'Your Name', Icons.person_outline, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco('Full name', Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Booker contact
                    _label(context, 'Mobile Number', Icons.phone_outlined, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userContactController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _deco('10-digit mobile number', Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Contact is required';
                        if (v.length != 10) return 'Enter valid 10-digit number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Event Location
                    _label(context, 'Event Location', Icons.location_on_outlined),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco('Venue / address of event', Icons.location_on_outlined),
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    _label(context, 'Notes', Icons.notes_outlined),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _deco('Any special requests...', Icons.notes_outlined).copyWith(alignLabelWithHint: true),
                    ),

                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _events.isEmpty) ? null : _handleSubmit,
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(_isSaving ? 'Submitting...' : 'Confirm Booking',
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
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(BuildContext context, String value, IconData icon, String label) {
    final isSelected = _paymentMethod == value;
    final color      = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : color.withOpacity(0.2), width: isSelected ? 2 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : color),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
          ]),
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

  Widget _warnBox(BuildContext context, String msg) {
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

  InputDecoration _deco(String hint, IconData icon) {
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