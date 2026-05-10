import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class GuestDetailsPage extends StatefulWidget {
  final UserModel user;

  const GuestDetailsPage({super.key, required this.user});

  @override
  State<GuestDetailsPage> createState() => _GuestDetailsPageState();
}

class _GuestDetailsPageState extends State<GuestDetailsPage> {
  // ── Step state ───────────────────────────────────────────────────────────────
  List<dynamic> events          = [];
  List<dynamic> guests          = [];
  Map<String, dynamic>? selectedGuest;
  dynamic selectedEvent;

  bool isLoadingEvents  = true;
  bool isLoadingGuests  = false;
  bool isLoadingDetails = false;
  bool isEditing        = false;
  bool isSaving         = false;

  // ── Edit controllers ─────────────────────────────────────────────────────────
  final _formKey             = GlobalKey<FormState>();
  final _notesController     = TextEditingController();
  final _seatingController   = TextEditingController();
  String? _editRsvpStatus;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _seatingController.dispose();
    super.dispose();
  }

  // ── Loaders ──────────────────────────────────────────────────────────────────

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
    setState(() {
      selectedEvent  = event;
      guests         = [];
      selectedGuest  = null;
      isLoadingGuests = true;
    });
    try {
      final data =
          await ApiService.getGuests(event["id"].toString());
      setState(() {
        guests          = data;
        isLoadingGuests = false;
      });
    } catch (e) {
      setState(() => isLoadingGuests = false);
    }
  }

  Future<void> _selectGuest(dynamic guest) async {
    setState(() {
      isLoadingDetails = true;
      isEditing        = false;
    });
    try {
      final data =
          await ApiService.getGuestById(guest["id"].toString());
      setState(() {
        selectedGuest    = data;
        isLoadingDetails = false;
        _populateControllers(data);
      });
    } catch (e) {
      setState(() => isLoadingDetails = false);
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _notesController.text   = data["notes"]   ?? "";
    _seatingController.text = data["seating"] ?? "";
    _editRsvpStatus         = data["rsvpStatus"] ?? "PENDING";
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _populateControllers(selectedGuest!);
    });
  }

  Future<void> _saveDetails() async {
    setState(() => isSaving = true);
    try {
      final updated = await ApiService.updateGuestDetails(
        selectedGuest!["id"].toString(),
        {
          "notes":      _notesController.text.trim(),
          "seating":    _seatingController.text.trim(),
          "rsvpStatus": _editRsvpStatus,
        },
      );
      setState(() {
        selectedGuest = updated;
        isEditing     = false;
        isSaving      = false;
        _populateControllers(updated);
        // Refresh guest in list
        final idx = guests.indexWhere((g) => g["id"] == updated["id"]);
        if (idx != -1) guests[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Guest details updated!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Update failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── RSVP helpers ─────────────────────────────────────────────────────────────

  Color _rsvpColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return Colors.green;
      case 'DECLINED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _rsvpIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'DECLINED':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    return isMobile
        ? _buildMobileLayout(context)
        : _buildWebLayout(context);
  }

  // ── Mobile layout ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    // Step 3: guest detail
    if (selectedGuest != null) {
      return Column(
        children: [
          _buildDetailHeader(context, isMobile: true),
          const Divider(height: 1),
          Expanded(
            child: isLoadingDetails
                ? const Center(child: CircularProgressIndicator())
                : _buildDetailsContent(context),
          ),
        ],
      );
    }
    // Step 2: guest list
    if (selectedEvent != null) {
      return Column(
        children: [
          _buildGuestListHeader(context),
          const Divider(height: 1),
          Expanded(child: _buildGuestList(context)),
        ],
      );
    }
    // Step 1: event selector
    return _buildEventSelector(context);
  }

  // ── Web layout: 3-column split ───────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Col 1 — event list (220px)
        Container(
          width: 220,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1)),
            ),
          ),
          child: _buildEventSelector(context),
        ),

        // Col 2 — guest list (260px)
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1)),
            ),
          ),
          child: selectedEvent == null
              ? _buildSelectEventPrompt(context)
              : Column(
                  children: [
                    _buildGuestListHeader(context),
                    const Divider(height: 1),
                    Expanded(child: _buildGuestList(context)),
                  ],
                ),
        ),

        // Col 3 — details
        Expanded(
          child: selectedGuest == null
              ? _buildSelectGuestPrompt(context)
              : isLoadingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildDetailHeader(context, isMobile: false),
                        const Divider(height: 1),
                        Expanded(child: _buildDetailsContent(context)),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Event selector panel ─────────────────────────────────────────────────────

  Widget _buildEventSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guest Details',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Select event then guest',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Divider(height: 1),
        events.isEmpty
            ? Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No events found',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall),
                      ],
                    ),
                  ),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e          = events[i];
                    final isSelected =
                        selectedEvent?["id"] == e["id"];
                    return InkWell(
                      onTap: () => _selectEvent(e),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e["name"] ?? "—",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : null,
                                )),
                            const SizedBox(height: 3),
                            Text(e["eventDate"] ?? "—",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // ── Guest list panel ─────────────────────────────────────────────────────────

  Widget _buildGuestListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          if (selectedGuest != null &&
              MediaQuery.of(context).size.width < 768)
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              onPressed: () => setState(() => selectedGuest = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          Expanded(
            child: Text(
              selectedEvent?["name"] ?? "Guests",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${guests.length}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGuestList(BuildContext context) {
    if (isLoadingGuests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.25)),
            const SizedBox(height: 12),
            Text('No guests added yet',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: guests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g          = guests[i];
        final isSelected =
            selectedGuest?["id"] == g["id"];
        final rsvp       = g["rsvpStatus"] ?? "PENDING";
        final rsvpColor  = _rsvpColor(rsvp);

        return InkWell(
          onTap: () => _selectGuest(g),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  child: Text(
                    (g["name"] ?? "G")[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g["name"] ?? "—",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(g["relation"] ?? "—",
                          style:
                              Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rsvpColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rsvp,
                      style: TextStyle(
                          fontSize: 9,
                          color: rsvpColor,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Detail header bar ────────────────────────────────────────────────────────

  Widget _buildDetailHeader(BuildContext context,
      {required bool isMobile}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: () =>
                  setState(() => selectedGuest = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (isMobile) const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedGuest?["name"] ?? "Guest Details",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isEditing)
            TextButton.icon(
              onPressed: () => setState(() => isEditing = true),
              icon: Icon(Icons.edit,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
              label: Text('Edit',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            )
          else ...[
            TextButton(
              onPressed: isSaving ? null : _cancelEdit,
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5))),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : _saveDetails,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Details content ──────────────────────────────────────────────────────────

  Widget _buildDetailsContent(BuildContext context) {
    final g = selectedGuest!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar + RSVP badge ──────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.12),
                    child: Text(
                      (g["name"] ?? "G")[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(g["name"] ?? "—",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  // RSVP badge
                  isEditing
                      ? DropdownButton<String>(
                          value: _editRsvpStatus,
                          underline: const SizedBox(),
                          items: ['PENDING', 'ACCEPTED', 'DECLINED']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Row(children: [
                                      Icon(_rsvpIcon(s),
                                          color: _rsvpColor(s),
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(s,
                                          style: TextStyle(
                                              color: _rsvpColor(s),
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _editRsvpStatus = val),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _rsvpColor(g["rsvpStatus"])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _rsvpColor(g["rsvpStatus"])
                                    .withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_rsvpIcon(g["rsvpStatus"]),
                                  color:
                                      _rsvpColor(g["rsvpStatus"]),
                                  size: 14),
                              const SizedBox(width: 6),
                              Text(
                                g["rsvpStatus"] ?? "PENDING",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _rsvpColor(g["rsvpStatus"]),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Personal Info (read-only) ────────────────────────────────
            _sectionHeader(context, 'Personal Information',
                Icons.person_outline),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(context, Icons.phone_outlined, 'Phone',
                        g["mobile"] ?? "—"),
                    const SizedBox(height: 14),
                    _infoRow(context, Icons.email_outlined, 'Email',
                        g["email"] ?? "—"),
                    const SizedBox(height: 14),
                    _infoRow(context, Icons.wc_outlined, 'Gender',
                        g["gender"] ?? "—"),
                    const SizedBox(height: 14),
                    _infoRow(context, Icons.people_outline, 'Relation',
                        g["relation"] ?? "—"),
                    const SizedBox(height: 14),
                    _infoRow(context, Icons.home_outlined, 'Address',
                        g["address"] ?? "—"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Seating & Notes (editable) ───────────────────────────────
            _sectionHeader(
                context, 'Seating & Notes', Icons.event_seat_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Seating
                    isEditing
                        ? Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(context, 'Seating',
                                  Icons.event_seat_outlined),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _seatingController,
                                decoration: _inputDecoration(
                                    'e.g. Table A, Row 3',
                                    Icons.event_seat_outlined),
                              ),
                            ],
                          )
                        : _infoRow(
                            context,
                            Icons.event_seat_outlined,
                            'Seating',
                            g["seating"] ?? "—",
                          ),

                    const SizedBox(height: 16),

                    // Notes
                    isEditing
                        ? Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(context, 'Notes',
                                  Icons.notes_outlined),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                        'Add any notes about this guest...',
                                        Icons.notes_outlined)
                                    .copyWith(
                                        alignLabelWithHint: true),
                              ),
                            ],
                          )
                        : _infoRow(
                            context,
                            Icons.notes_outlined,
                            'Notes',
                            g["notes"] ?? "—",
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Empty prompts ────────────────────────────────────────────────────────────

  Widget _buildSelectEventPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('Select an event',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSelectGuestPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('Select a guest to view details',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5))),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(
      BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon,
          color: Theme.of(context).colorScheme.primary, size: 18),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }
}