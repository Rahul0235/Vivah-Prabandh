import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class GuestListPage extends StatefulWidget {
  final UserModel user;
  const GuestListPage({super.key, required this.user});

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  List<dynamic> events         = [];
  List<dynamic> allGuests      = [];
  List<dynamic> filteredGuests = [];

  dynamic  selectedEvent;
  String?  selectedGender;
  String?  selectedRsvp;
  String   searchQuery = '';

  bool isLoadingEvents = true;
  bool isLoadingGuests = false;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _genderOptions = ['MALE', 'FEMALE'];
  final List<String> _rsvpOptions   = ['PENDING', 'ACCEPTED', 'DECLINED'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ApiService.getUserEvents(widget.user.id);
      setState(() {
        events          = data;
        isLoadingEvents = false;
        if (events.length == 1) _onEventSelected(events[0]);
      });
    } catch (e) {
      setState(() => isLoadingEvents = false);
    }
  }

  Future<void> _onEventSelected(dynamic event) async {
    setState(() {
      selectedEvent    = event;
      isLoadingGuests  = true;
      allGuests        = [];
      filteredGuests   = [];
      searchQuery      = '';
      selectedGender   = null;
      selectedRsvp     = null;
      _searchController.clear();
    });
    try {
      final data = await ApiService.getGuests(event["id"].toString());
      setState(() {
        allGuests       = data;
        filteredGuests  = data;
        isLoadingGuests = false;
      });
    } catch (e) {
      setState(() => isLoadingGuests = false);
    }
  }

  void _applyFilters() {
    List<dynamic> result = List.from(allGuests);

    if (searchQuery.isNotEmpty) {
      result = result.where((g) =>
          (g["name"] ?? "").toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    if (selectedGender != null) {
      result = result.where((g) =>
          (g["gender"] ?? "").toUpperCase() == selectedGender!.toUpperCase()).toList();
    }
    if (selectedRsvp != null) {
      result = result.where((g) =>
          (g["rsvpStatus"] ?? "").toUpperCase() == selectedRsvp!.toUpperCase()).toList();
    }

    setState(() => filteredGuests = result);
  }

  void _clearFilters() {
    setState(() {
      selectedGender = null;
      selectedRsvp   = null;
      searchQuery    = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      selectedGender != null || selectedRsvp != null || searchQuery.isNotEmpty;

  Color _rsvpColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'ACCEPTED': return Colors.green;
      case 'DECLINED': return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData _rsvpIcon(String? s) {
    switch (s?.toUpperCase()) {
      case 'ACCEPTED': return Icons.check_circle;
      case 'DECLINED': return Icons.cancel;
      default:          return Icons.hourglass_empty;
    }
  }

  int _countByRsvp(String status) =>
      allGuests.where((g) =>
          (g["rsvpStatus"] ?? "").toUpperCase() == status.toUpperCase()).length;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());
    return isMobile ? _buildMobileLayout(context) : _buildWebLayout(context);
  }

  // ── Mobile ────────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guest List', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('View and filter all guests', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildEventDropdown(context)),
        if (selectedEvent != null) ...[
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSummaryRow(context)),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSearchBar(context)),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildFilterChips(context)),
          const SizedBox(height: 8),
        ],
        const Divider(height: 1),
        Expanded(child: _buildGuestListBody(context)),
      ],
    );
  }

  // ── Web ───────────────────────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left filter panel
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1))),
          ),
          child: _buildFilterPanel(context),
        ),
        // Right content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guest List', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            selectedEvent == null
                                ? 'Select an event to view guests'
                                : '${filteredGuests.length} of ${allGuests.length} guests',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (selectedEvent != null) _buildSummaryRow(context),
                  ],
                ),
              ),
              if (selectedEvent != null) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildSearchBar(context)),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildFilterChips(context)),
                const SizedBox(height: 8),
              ],
              const Divider(height: 1),
              Expanded(child: _buildGuestListBody(context)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Filter panel (web sidebar) ────────────────────────────────────────────────

  Widget _buildFilterPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          _filterLabel(context, 'Event', Icons.event_outlined),
          const SizedBox(height: 8),
          _buildEventDropdown(context),

          if (selectedEvent != null) ...[
            const SizedBox(height: 20),

            _filterLabel(context, 'Gender', Icons.wc_outlined),
            const SizedBox(height: 8),
            ..._genderOptions.map((g) => _buildRadioTile(
              context, label: g, value: g, groupValue: selectedGender,
              onTap: () { setState(() => selectedGender = selectedGender == g ? null : g); _applyFilters(); },
            )),

            const SizedBox(height: 16),

            _filterLabel(context, 'RSVP Status', Icons.mark_email_read_outlined),
            const SizedBox(height: 8),
            ..._rsvpOptions.map((r) => _buildRadioTile(
              context, label: r, value: r, groupValue: selectedRsvp,
              color: _rsvpColor(r),
              onTap: () { setState(() => selectedRsvp = selectedRsvp == r ? null : r); _applyFilters(); },
            )),

            if (_hasActiveFilters) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────────

  Widget _buildEventDropdown(BuildContext context) {
    if (events.isEmpty) {
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
          Text('No events found', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
        ]),
      );
    }
    return DropdownButtonFormField<dynamic>(
      value: selectedEvent,
      decoration: InputDecoration(
        hintText: 'Select event',
        prefixIcon: Icon(Icons.event_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
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
      ),
      items: events.map((e) => DropdownMenuItem(value: e, child: Text(e["name"] ?? "—", overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (val) { if (val != null) _onEventSelected(val); },
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _summaryChip(context, '${allGuests.length}',       'Total',    Colors.blue),
        const SizedBox(width: 6),
        _summaryChip(context, '${_countByRsvp("ACCEPTED")}','Accepted', Colors.green),
        const SizedBox(width: 6),
        _summaryChip(context, '${_countByRsvp("PENDING")}', 'Pending',  Colors.orange),
        const SizedBox(width: 6),
        _summaryChip(context, '${_countByRsvp("DECLINED")}','Declined', Colors.red),
      ],
    );
  }

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

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (val) { searchQuery = val; _applyFilters(); },
      decoration: InputDecoration(
        hintText: 'Search guests by name...',
        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); searchQuery = ''; _applyFilters(); })
            : null,
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
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: [
        ..._genderOptions.map((g) => _filterChip(context, label: g, selected: selectedGender == g, onSelected: (val) { setState(() => selectedGender = val ? g : null); _applyFilters(); })),
        ..._rsvpOptions.map((r) => _filterChip(context, label: r, selected: selectedRsvp == r, color: _rsvpColor(r), onSelected: (val) { setState(() => selectedRsvp = val ? r : null); _applyFilters(); })),
        if (_hasActiveFilters) ActionChip(label: const Text('Clear All'), avatar: const Icon(Icons.clear, size: 14), onPressed: _clearFilters, backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ],
    );
  }

  Widget _filterChip(BuildContext context, {required String label, required bool selected, required ValueChanged<bool> onSelected, Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : c, fontWeight: FontWeight.w600)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: c,
      checkmarkColor: Colors.white,
      backgroundColor: c.withOpacity(0.1),
      side: BorderSide(color: selected ? c : c.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildRadioTile(BuildContext context, {required String label, required String value, required String? groupValue, required VoidCallback onTap, Color? color}) {
    final isSelected = groupValue == value;
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? c : Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? c : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: isSelected ? c : null, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  // ── Guest list body ───────────────────────────────────────────────────────────

  Widget _buildGuestListBody(BuildContext context) {
    if (selectedEvent == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('Select an event to view guests', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ]));
    }
    if (isLoadingGuests) return const Center(child: CircularProgressIndicator());
    if (allGuests.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('No guests added yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ]));
    }
    if (filteredGuests.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('No guests match your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        const SizedBox(height: 8),
        TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
      ]));
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    return RefreshIndicator(
      onRefresh: () => _onEventSelected(selectedEvent),
      child: isMobile ? _buildMobileList(context) : _buildWebGrid(context),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGuests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _buildGuestCard(context, filteredGuests[i]),
    );
  }

  Widget _buildWebGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.6,
        ),
        itemCount: filteredGuests.length,
        itemBuilder: (context, i) => _buildGuestCard(context, filteredGuests[i]),
      );
    });
  }

  Widget _buildGuestCard(BuildContext context, Map<String, dynamic> g) {
    final rsvp      = g["rsvpStatus"] ?? "PENDING";
    final rsvpColor = _rsvpColor(rsvp);
    final gender    = g["gender"] ?? "—";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text((g["name"] ?? "G")[0].toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(g["name"] ?? "—", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.people_outline, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(g["relation"] ?? "—", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(gender.toUpperCase() == 'MALE' ? Icons.male : Icons.female, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(gender, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                  ]),
                  if ((g["mobile"] ?? "").isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.phone_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                      const SizedBox(width: 4),
                      Text(g["mobile"], style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                    ]),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_rsvpIcon(rsvp), color: rsvpColor, size: 20),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: rsvpColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(rsvp, style: TextStyle(fontSize: 9, color: rsvpColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterLabel(BuildContext context, String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }
}