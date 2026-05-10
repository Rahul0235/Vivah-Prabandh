import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class BudgetOverviewPage extends StatefulWidget {
  final UserModel user;
  const BudgetOverviewPage({super.key, required this.user});

  @override
  State<BudgetOverviewPage> createState() => _BudgetOverviewPageState();
}

class _BudgetOverviewPageState extends State<BudgetOverviewPage> {
  List<dynamic> events          = [];
  dynamic       selectedEvent;
  Map<String, dynamic>? overview;

  bool isLoadingEvents  = true;
  bool isLoadingOverview = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
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
    setState(() {
      selectedEvent      = event;
      overview           = null;
      isLoadingOverview  = true;
    });
    try {
      final data = await ApiService.getBudgetOverview(event["id"].toString());
      setState(() {
        overview          = data;
        isLoadingOverview = false;
      });
    } catch (e) {
      setState(() => isLoadingOverview = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load budget: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _fmt(dynamic val) {
    if (val == null) return "₹0";
    final d = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
    if (d >= 100000) return "₹${(d / 100000).toStringAsFixed(1)}L";
    if (d >= 1000)   return "₹${(d / 1000).toStringAsFixed(1)}K";
    return "₹${d.toStringAsFixed(0)}";
  }

  double _safeDouble(dynamic val) =>
      (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? "0") ?? 0.0;

  double _spentPercent() {
    final total = _safeDouble(overview?["totalBudget"]);
    final spent = _safeDouble(overview?["totalSpent"]);
    if (total <= 0) return 0.0;
    return (spent / total).clamp(0.0, 1.0);
  }

  Color _progressColor() {
    final p = _spentPercent();
    if (p >= 0.9) return Colors.red;
    if (p >= 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ───────────────────────────────────────────────────
              Text('Budget Overview', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Track your event budget and spending', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),

              // ── Event Selector ────────────────────────────────────────────
              _buildEventDropdown(context),
              const SizedBox(height: 24),

              // ── Overview content ──────────────────────────────────────────
              if (selectedEvent == null)
                _buildEmptyState(context, Icons.event_outlined, 'Select an event to view budget')
              else if (isLoadingOverview)
                const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
              else if (overview == null)
                _buildEmptyState(context, Icons.account_balance_wallet_outlined, 'No budget data available')
              else ...[
                // Stat cards
                isMobile
                    ? Column(children: _buildStatCards(context))
                    : Row(
                        children: _buildStatCards(context)
                            .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w)))
                            .toList(),
                      ),

                const SizedBox(height: 24),

                // Progress card
                _buildProgressCard(context),

                const SizedBox(height: 24),

                // Budget health card
                _buildHealthCard(context),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildEventDropdown(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Text('No events found. Create an event first.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
        ]),
      );
    }

    return DropdownButtonFormField<dynamic>(
      value: selectedEvent,
      decoration: InputDecoration(
        labelText: 'Select Event',
        prefixIcon: Icon(Icons.event_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      items: events.map((e) => DropdownMenuItem(
        value: e,
        child: Text("${e["name"] ?? "—"}  •  ${e["eventDate"] ?? ""}", overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (val) { if (val != null) _selectEvent(val); },
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    final totalBudget     = _safeDouble(overview?["totalBudget"]);
    final totalSpent      = _safeDouble(overview?["totalSpent"]);
    final remainingBudget = _safeDouble(overview?["remainingBudget"]);
    final isOver          = remainingBudget < 0;

    return [
      _statCard(
        context,
        label:    'Total Budget',
        value:    _fmt(totalBudget),
        icon:     Icons.account_balance_wallet_outlined,
        color:    Colors.blue,
        subtitle: 'Allocated for this event',
      ),
      SizedBox(height: MediaQuery.of(context).size.width < 768 ? 12 : 0),
      _statCard(
        context,
        label:    'Total Spent',
        value:    _fmt(totalSpent),
        icon:     Icons.shopping_cart_outlined,
        color:    Colors.purple,
        subtitle: '${(_spentPercent() * 100).toStringAsFixed(1)}% of budget used',
      ),
      SizedBox(height: MediaQuery.of(context).size.width < 768 ? 12 : 0),
      _statCard(
        context,
        label:    isOver ? 'Over Budget' : 'Remaining',
        value:    isOver ? _fmt(remainingBudget.abs()) : _fmt(remainingBudget),
        icon:     isOver ? Icons.warning_amber_outlined : Icons.savings_outlined,
        color:    isOver ? Colors.red : Colors.green,
        subtitle: isOver ? 'Exceeded budget limit' : 'Still available to spend',
        highlight: true,
        highlightColor: isOver ? Colors.red : Colors.green,
      ),
    ];
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool highlight = false,
    Color? highlightColor,
  }) {
    final hColor = highlightColor ?? color;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight
            ? BorderSide(color: hColor.withOpacity(0.4), width: 2)
            : BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('KEY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: hColor)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final percent     = _spentPercent();
    final pColor      = _progressColor();
    final totalBudget = _safeDouble(overview?["totalBudget"]);
    final totalSpent  = _safeDouble(overview?["totalSpent"]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text('Spending Progress', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 20),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹0', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}% spent',
                  style: TextStyle(fontWeight: FontWeight.w700, color: pColor, fontSize: 13),
                ),
                Text(_fmt(totalBudget), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 14,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(pColor),
              ),
            ),
            const SizedBox(height: 16),

            // Spent / Remaining row
            Row(children: [
              _progressLegend(context, pColor,   'Spent',     _fmt(totalSpent)),
              const SizedBox(width: 24),
              _progressLegend(context, Theme.of(context).colorScheme.primary.withOpacity(0.2), 'Remaining', _fmt(_safeDouble(overview?["remainingBudget"]))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _progressLegend(BuildContext context, Color color, String label, String value) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ]);
  }

  Widget _buildHealthCard(BuildContext context) {
    final percent = _spentPercent();
    final remaining = _safeDouble(overview?["remainingBudget"]);

    String title, message;
    IconData icon;
    Color color;

    if (remaining < 0) {
      title   = "Over Budget!";
      message = "You have exceeded your budget by ${_fmt(remaining.abs())}. Consider reviewing your expenses.";
      icon    = Icons.warning_amber;
      color   = Colors.red;
    } else if (percent >= 0.9) {
      title   = "Almost at Limit";
      message = "You've used ${(percent * 100).toStringAsFixed(0)}% of your budget. Only ${_fmt(remaining)} remains.";
      icon    = Icons.error_outline;
      color   = Colors.orange;
    } else if (percent >= 0.7) {
      title   = "Spending on Track";
      message = "You've used ${(percent * 100).toStringAsFixed(0)}% of your budget. Keep monitoring your expenses.";
      icon    = Icons.info_outline;
      color   = Colors.blue;
    } else {
      title   = "Budget Healthy";
      message = "Great! You have ${_fmt(remaining)} remaining. You're well within your budget.";
      icon    = Icons.check_circle_outline;
      color   = Colors.green;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                  const SizedBox(height: 6),
                  Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }
}