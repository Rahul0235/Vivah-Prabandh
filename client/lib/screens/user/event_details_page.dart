import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class EventDetailsPage extends StatefulWidget {
  final UserModel user;

  const EventDetailsPage({super.key, required this.user});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  List<dynamic> events      = [];
  Map<String, dynamic>? selectedEvent;
  bool isLoadingEvents      = true;
  bool isLoadingDetails     = false;
  bool isEditing            = false;
  bool isSaving             = false;

  // Edit controllers
  final _formKey                  = GlobalKey<FormState>();
  final _functionTypeController   = TextEditingController();
  final _timeController           = TextEditingController();
  final _venueController          = TextEditingController();
  final _descriptionController    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _functionTypeController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ApiService.getUserEvents(widget.user.id);
      setState(() {
        events         = data;
        isLoadingEvents = false;
      });
    } catch (e) {
      setState(() => isLoadingEvents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load events: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadEventDetails(dynamic event) async {
    setState(() {
      isLoadingDetails = true;
      isEditing        = false;
    });
    try {
      final data = await ApiService.getEventById(event["id"].toString());
      setState(() {
        selectedEvent    = data;
        isLoadingDetails = false;
        _populateControllers(data);
      });
    } catch (e) {
      setState(() => isLoadingDetails = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load details: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _functionTypeController.text = data["functionType"] ?? "";
    _timeController.text         = data["time"]         ?? "";
    _venueController.text        = data["venue"]        ?? "";
    _descriptionController.text  = data["description"]  ?? "";
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _populateControllers(selectedEvent!);
    });
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final updated = await ApiService.updateEventDetails(
        selectedEvent!["id"].toString(),
        {
          "functionType": _functionTypeController.text.trim(),
          "time":         _timeController.text.trim(),
          "venue":        _venueController.text.trim(),
          "description":  _descriptionController.text.trim(),
        },
      );
      setState(() {
        selectedEvent = updated;
        isEditing     = false;
        isSaving      = false;
        _populateControllers(updated);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Event details updated!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // ── No Scaffold — embeds inline ───────────────────────────────────────────
    return isLoadingEvents
        ? const Center(child: CircularProgressIndicator())
        : isMobile
            ? _buildMobileLayout(context)
            : _buildWebLayout(context);
  }

  // ── Mobile: show event list, tap to open details ────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    if (selectedEvent != null) {
      return Column(
        children: [
          // Back to list bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: () => setState(() {
                  selectedEvent = null;
                  isEditing     = false;
                }),
              ),
              title: Text(
                selectedEvent!["name"] ?? "Event Details",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: isEditing
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                          onPressed: isSaving ? null : _cancelEdit,
                          child: const Text("Cancel")),
                      ElevatedButton(
                          onPressed: isSaving ? null : _saveDetails,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text("Save")),
                    ])
                  : TextButton.icon(
                      onPressed: () => setState(() => isEditing = true),
                      icon: Icon(Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      label: Text("Edit",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
              child: isLoadingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDetailsContent(context)),
        ],
      );
    }
    return _buildEventList(context);
  }

  // ── Web: split view — list on left, details on right ───────────────────────
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — event list
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            ),
          ),
          child: _buildEventList(context),
        ),

        // Right panel — event details
        Expanded(
          child: selectedEvent == null
              ? _buildEmptySelection(context)
              : isLoadingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Detail header bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedEvent!["name"] ?? "Event Details",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              isEditing
                                  ? Row(children: [
                                      TextButton(
                                          onPressed:
                                              isSaving ? null : _cancelEdit,
                                          child: Text("Cancel",
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6)))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                          onPressed:
                                              isSaving ? null : _saveDetails,
                                          style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          child: isSaving
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2))
                                              : const Text("Save Changes")),
                                    ])
                                  : TextButton.icon(
                                      onPressed: () =>
                                          setState(() => isEditing = true),
                                      icon: Icon(Icons.edit,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      label: Text("Edit Details",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w600)),
                                    ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildDetailsContent(context)),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Event list ──────────────────────────────────────────────────────────────
  Widget _buildEventList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Details',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Select an event to view or edit details',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Divider(height: 1),
        events.isEmpty
            ? Expanded(child: _buildNoEvents(context))
            : Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isSelected =
                        selectedEvent?["id"] == event["id"];
                    return InkWell(
                      onTap: () => _loadEventDetails(event),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Theme.of(context)
                                  .colorScheme
                                  .surface,
                          borderRadius: BorderRadius.circular(12),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.celebration,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event["name"] ?? "—",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Icon(Icons.calendar_today,
                                        size: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5)),
                                    const SizedBox(width: 4),
                                    Text(event["eventDate"] ?? "—",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ]),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(Icons.location_on,
                                        size: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(event["location"] ?? "—",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.primary),
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

  // ── Details content ─────────────────────────────────────────────────────────
  Widget _buildDetailsContent(BuildContext context) {
    final event = selectedEvent!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Basic Info Card (read-only) ─────────────────────────────────
            _buildSectionHeader(context, 'Basic Information', Icons.info_outline),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(context, Icons.celebration_outlined,
                        'Event Name', event["name"] ?? "—"),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.calendar_today_outlined,
                        'Event Date', event["eventDate"] ?? "—"),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.location_on_outlined,
                        'Location', event["location"] ?? "—"),
                    if (event["totalBudget"] != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(context, Icons.currency_rupee,
                          'Total Budget', "₹${event["totalBudget"]}"),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Function Info Card (editable) ──────────────────────────────
            _buildSectionHeader(
                context, 'Function Information', Icons.event_note_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    // Function Type
                    isEditing
                        ? _buildEditField(
                            context,
                            controller: _functionTypeController,
                            label: 'Function Type',
                            hint: 'e.g. Wedding, Reception, Mehendi',
                            icon: Icons.category_outlined,
                          )
                        : _buildInfoRow(
                            context,
                            Icons.category_outlined,
                            'Function Type',
                            event["functionType"] ?? "—",
                          ),

                    const SizedBox(height: 16),

                    // Time
                    isEditing
                        ? _buildEditField(
                            context,
                            controller: _timeController,
                            label: 'Time',
                            hint: 'e.g. 07:00 PM',
                            icon: Icons.access_time_outlined,
                          )
                        : _buildInfoRow(
                            context,
                            Icons.access_time_outlined,
                            'Time',
                            event["time"] ?? "—",
                          ),

                    const SizedBox(height: 16),

                    // Venue
                    isEditing
                        ? _buildEditField(
                            context,
                            controller: _venueController,
                            label: 'Venue',
                            hint: 'e.g. Taj Palace Banquet Hall',
                            icon: Icons.place_outlined,
                          )
                        : _buildInfoRow(
                            context,
                            Icons.place_outlined,
                            'Venue',
                            event["venue"] ?? "—",
                          ),

                    const SizedBox(height: 16),

                    // Description
                    isEditing
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context, 'Description',
                                  Icons.description_outlined),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: _inputDecoration(
                                  'Add event description or special notes...',
                                  Icons.description_outlined,
                                ).copyWith(alignLabelWithHint: true),
                              ),
                            ],
                          )
                        : _buildInfoRow(
                            context,
                            Icons.description_outlined,
                            'Description',
                            event["description"] ?? "—",
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

  // ── Empty states ────────────────────────────────────────────────────────────
  Widget _buildEmptySelection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Select an event',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  )),
          const SizedBox(height: 8),
          Text('Choose an event from the list to view its details',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildNoEvents(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 56,
              color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No events yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  )),
          const SizedBox(height: 8),
          Text('Create an event first from the sidebar',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
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
                        .withOpacity(0.5),
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(
      BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            )),
      ],
    );
  }

  Widget _buildEditField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, label, icon),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint, icon),
        ),
        const SizedBox(height: 4),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }
}