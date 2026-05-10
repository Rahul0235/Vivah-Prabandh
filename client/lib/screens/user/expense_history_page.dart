import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class ExpenseHistoryPage extends StatefulWidget {
  final UserModel user;
  const ExpenseHistoryPage({super.key, required this.user});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  // ── Data ─────────────────────────────────────────────────────────────────────
  List<dynamic> events   = [];
  List<dynamic> expenses = [];
  dynamic       selectedEvent;

  // ── Filters ───────────────────────────────────────────────────────────────────
  String?   selectedCategory;
  DateTime? startDate;
  DateTime? endDate;

  // ── State ─────────────────────────────────────────────────────────────────────
  bool isLoadingEvents   = true;
  bool isLoadingExpenses = false;

  // ── Category options ──────────────────────────────────────────────────────────
  final List<String> _categories = [
    'Catering', 'Decoration', 'Photography', 'Videography',
    'Venue', 'Music / DJ', 'Makeup', 'Mehendi',
    'Transport', 'Clothing', 'Invitation', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // ── Loaders ───────────────────────────────────────────────────────────────────

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
      selectedEvent      = event;
      expenses           = [];
      selectedCategory   = null;
      startDate          = null;
      endDate            = null;
      isLoadingExpenses  = true;
    });
    await _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    if (selectedEvent == null) return;
    setState(() => isLoadingExpenses = true);
    try {
      final data = await ApiService.getExpenses(
        selectedEvent["id"].toString(),
        category:  selectedCategory,
        startDate: startDate  != null ? _toApiDate(startDate!)  : null,
        endDate:   endDate    != null ? _toApiDate(endDate!)    : null,
      );
      setState(() {
        expenses          = data;
        isLoadingExpenses = false;
      });
    } catch (e) {
      setState(() => isLoadingExpenses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load expenses: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Date pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: endDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => startDate = picked);
      _fetchExpenses();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => endDate = picked);
      _fetchExpenses();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      startDate        = null;
      endDate          = null;
    });
    _fetchExpenses();
  }

  bool get _hasActiveFilters =>
      selectedCategory != null || startDate != null || endDate != null;

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _toApiDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "${dt.year}-$m-$d";
  }

  String _fmtDate(String? raw) {
    if (raw == null) return "—";
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) { return raw; }
  }

  String _fmtDateShort(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${dt.day} ${months[dt.month - 1]}";
  }

  String _fmtAmount(dynamic val) {
    if (val == null) return "₹0";
    final d = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
    return "₹${d.toStringAsFixed(0)}";
  }

  double get _totalAmount => expenses.fold(0.0, (sum, e) =>
      sum + ((e["amount"] is num) ? (e["amount"] as num).toDouble() : 0.0));

  Color _categoryColor(String? cat) {
    const map = {
      'Catering':     Colors.orange,
      'Decoration':   Colors.pink,
      'Photography':  Colors.blue,
      'Videography':  Colors.indigo,
      'Venue':        Colors.teal,
      'Music / DJ':   Colors.purple,
      'Makeup':       Colors.red,
      'Mehendi':      Colors.brown,
      'Transport':    Colors.cyan,
      'Clothing':     Colors.green,
      'Invitation':   Colors.amber,
    };
    return map[cat] ?? Colors.grey;
  }

  IconData _categoryIcon(String? cat) {
    const map = {
      'Catering':     Icons.restaurant_outlined,
      'Decoration':   Icons.celebration_outlined,
      'Photography':  Icons.camera_alt_outlined,
      'Videography':  Icons.videocam_outlined,
      'Venue':        Icons.location_on_outlined,
      'Music / DJ':   Icons.music_note_outlined,
      'Makeup':       Icons.face_retouching_natural,
      'Mehendi':      Icons.palette_outlined,
      'Transport':    Icons.directions_car_outlined,
      'Clothing':     Icons.checkroom_outlined,
      'Invitation':   Icons.mail_outline,
    };
    return map[cat] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());
    return isMobile ? _buildMobileLayout(context) : _buildWebLayout(context);
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + event selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expense History', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('View and filter your expenses', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              _buildEventDropdown(context),
            ],
          ),
        ),

        if (selectedEvent != null) ...[
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFiltersRow(context, isMobile: true),
          ),
          const SizedBox(height: 8),

          // Active filter chips
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActiveFilterChips(context),
            ),

          // Summary bar
          if (expenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildSummaryBar(context),
            ),
          const SizedBox(height: 8),
        ],

        const Divider(height: 1),
        Expanded(child: _buildExpenseListBody(context)),
      ],
    );
  }

  // ── Web layout ────────────────────────────────────────────────────────────────

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
                          Text('Expense History', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            selectedEvent == null
                                ? 'Select an event to view expenses'
                                : '${expenses.length} expenses',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (expenses.isNotEmpty) _buildSummaryBar(context),
                  ],
                ),
              ),
              if (_hasActiveFilters && selectedEvent != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _buildActiveFilterChips(context),
                ),
              const Divider(height: 1),
              Expanded(child: _buildExpenseListBody(context)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Filter panel (web) ────────────────────────────────────────────────────────

  Widget _buildFilterPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Event
          _filterLabel(context, 'Event', Icons.event_outlined),
          const SizedBox(height: 8),
          _buildEventDropdown(context),

          if (selectedEvent != null) ...[
            const SizedBox(height: 20),

            // Category
            _filterLabel(context, 'Category', Icons.category_outlined),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: _inputDeco('All categories', Icons.category_outlined),
              items: [
                const DropdownMenuItem(value: null, child: Text('All categories')),
                ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (val) { setState(() => selectedCategory = val); _fetchExpenses(); },
            ),

            const SizedBox(height: 20),

            // Date range
            _filterLabel(context, 'Date Range', Icons.date_range_outlined),
            const SizedBox(height: 8),
            _datePicker(context, label: 'From', date: startDate, onTap: _pickStartDate),
            const SizedBox(height: 8),
            _datePicker(context, label: 'To', date: endDate, onTap: _pickEndDate),

            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
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

  // ── Mobile filters row ────────────────────────────────────────────────────────

  Widget _buildFiltersRow(BuildContext context, {required bool isMobile}) {
    final hasDate = startDate != null || endDate != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category dropdown — full width
        DropdownButtonFormField<String>(
          value: selectedCategory,
          isExpanded: true,
          decoration: _inputDeco('All categories', Icons.category_outlined),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: (val) { setState(() => selectedCategory = val); _fetchExpenses(); },
        ),
        const SizedBox(height: 8),
        // Date range button — full width
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDateRangeSheet(context),
            icon: Icon(Icons.date_range_outlined,
                size: 16, color: hasDate ? Theme.of(context).colorScheme.primary : null),
            label: Text(
              hasDate ? 'Date Range ✓' : 'Select Date Range',
              style: TextStyle(color: hasDate ? Theme.of(context).colorScheme.primary : null),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              side: BorderSide(
                color: hasDate
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile date range bottom sheet ────────────────────────────────────────────

  void _showDateRangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date Range', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _datePicker(context, label: 'From', date: startDate, onTap: () async {
              Navigator.pop(ctx);
              await _pickStartDate();
            }),
            const SizedBox(height: 10),
            _datePicker(context, label: 'To', date: endDate, onTap: () async {
              Navigator.pop(ctx);
              await _pickEndDate();
            }),
            const SizedBox(height: 16),
            if (startDate != null || endDate != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _clearFilters(); },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Dates'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Active filter chips ────────────────────────────────────────────────────────

  Widget _buildActiveFilterChips(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: [
        if (selectedCategory != null)
          Chip(
            label: Text(selectedCategory!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
            deleteIcon: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.primary),
            onDeleted: () { setState(() => selectedCategory = null); _fetchExpenses(); },
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
        if (startDate != null)
          Chip(
            label: Text('From ${_fmtDateShort(startDate!)}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue.shade700),
            onDeleted: () { setState(() => startDate = null); _fetchExpenses(); },
            backgroundColor: Colors.blue.withOpacity(0.1),
            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
          ),
        if (endDate != null)
          Chip(
            label: Text('To ${_fmtDateShort(endDate!)}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue.shade700),
            onDeleted: () { setState(() => endDate = null); _fetchExpenses(); },
            backgroundColor: Colors.blue.withOpacity(0.1),
            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
          ),
        if (_hasActiveFilters)
          ActionChip(
            label: const Text('Clear All', style: TextStyle(fontSize: 12)),
            avatar: const Icon(Icons.clear, size: 14),
            onPressed: _clearFilters,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          ),
      ],
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────────

  Widget _buildSummaryBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('${expenses.length} items  •  ', style: Theme.of(context).textTheme.bodySmall),
        Text(
          '₹${_totalAmount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary, fontSize: 14),
        ),
      ]),
    );
  }

  // ── Expense list body ─────────────────────────────────────────────────────────

  Widget _buildExpenseListBody(BuildContext context) {
    if (selectedEvent == null) {
      return _emptyState(context, Icons.event_outlined, 'Select an event to view expenses');
    }
    if (isLoadingExpenses) return const Center(child: CircularProgressIndicator());
    if (expenses.isEmpty) {
      return _hasActiveFilters
          ? _emptyState(context, Icons.search_off, 'No expenses match your filters',
              action: TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')))
          : _emptyState(context, Icons.receipt_long_outlined, 'No expenses added yet');
    }

    return RefreshIndicator(
      onRefresh: _fetchExpenses,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildExpenseCard(context, expenses[i]),
      ),
    );
  }

  // ── Expense card ──────────────────────────────────────────────────────────────

  Widget _buildExpenseCard(BuildContext context, Map<String, dynamic> e) {
    final category = e["category"] ?? "Other";
    final color    = _categoryColor(category);
    final icon     = _categoryIcon(category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (e["description"] != null && (e["description"] as String).isNotEmpty)
                    Text(e["description"], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.calendar_today, size: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(_fmtDate(e["date"]), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ],
              ),
            ),

            // Amount
            Text(
              _fmtAmount(e["amount"]),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

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
      decoration: _inputDeco('Select event', Icons.event_outlined),
      items: events.map((e) => DropdownMenuItem(
        value: e,
        child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (val) { if (val != null) _onEventSelected(val); },
    );
  }

  Widget _datePicker(BuildContext context, {required String label, required DateTime? date, required VoidCallback onTap}) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: hasDate ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            hasDate ? '$label: ${_fmtDateShort(date)}' : label,
            style: TextStyle(
              fontSize: 13,
              color: hasDate ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState(BuildContext context, IconData icon, String message, {Widget? action}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 60, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        if (action != null) action,
      ]),
    );
  }

  Widget _filterLabel(BuildContext context, String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
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