import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class ExpenseAnalysisPage extends StatefulWidget {
  final UserModel user;
  const ExpenseAnalysisPage({super.key, required this.user});

  @override
  State<ExpenseAnalysisPage> createState() => _ExpenseAnalysisPageState();
}

class _ExpenseAnalysisPageState extends State<ExpenseAnalysisPage> {
  List<dynamic> events          = [];
  dynamic       selectedEvent;
  List<dynamic> categoryData    = [];
  List<dynamic> monthlyData     = [];

  bool isLoadingEvents   = true;
  bool isLoadingCharts   = false;
  int  touchedPieIndex   = -1;

  // ── Category colors ───────────────────────────────────────────────────────────
  final List<Color> _pieColors = [
    const Color(0xFFB76E79),
    const Color(0xFF5C85D6),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
    const Color(0xFFE91E63),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
    const Color(0xFFCDDC39),
    const Color(0xFFFF5722),
    const Color(0xFF3F51B5),
  ];

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
      selectedEvent    = event;
      categoryData     = [];
      monthlyData      = [];
      isLoadingCharts  = true;
    });
    try {
      final id = event["id"].toString();
      final cat     = await ApiService.getCategoryAnalytics(id);
      final monthly = await ApiService.getMonthlyAnalytics(id);
      setState(() {
        categoryData   = cat;
        monthlyData    = monthly;
        isLoadingCharts = false;
      });
    } catch (e) {
      setState(() => isLoadingCharts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load analytics: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  double _safeDouble(dynamic val) =>
      (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? "0") ?? 0.0;

  double get _totalCategory =>
      categoryData.fold(0.0, (s, e) => s + _safeDouble(e["totalAmount"]));

  String _fmtAmount(double val) {
    if (val >= 100000) return "₹${(val / 100000).toStringAsFixed(1)}L";
    if (val >= 1000)   return "₹${(val / 1000).toStringAsFixed(1)}K";
    return "₹${val.toStringAsFixed(0)}";
  }

  String _fmtMonth(String? raw) {
    if (raw == null) return "";
    try {
      final parts = raw.split("-");
      if (parts.length < 2) return raw;
      const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final m = int.tryParse(parts[1]) ?? 0;
      return "${months[m]} '${parts[0].substring(2)}";
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoadingEvents) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────────────────────────
          Text('Expense Analysis', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Visual breakdown of your spending', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // ── Event selector ──────────────────────────────────────────────────
          _buildEventDropdown(context),
          const SizedBox(height: 24),

          if (selectedEvent == null)
            _emptyState(context, Icons.bar_chart_outlined, 'Select an event to view analytics')
          else if (isLoadingCharts)
            const Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator()))
          else if (categoryData.isEmpty && monthlyData.isEmpty)
            _emptyState(context, Icons.receipt_long_outlined, 'No expense data yet for this event')
          else ...[

            // ── Charts layout ─────────────────────────────────────────────────
            if (isMobile) ...[
              // Mobile: stacked
              if (categoryData.isNotEmpty) ...[
                _buildPieChartCard(context),
                const SizedBox(height: 20),
              ],
              if (monthlyData.isNotEmpty)
                _buildBarChartCard(context),
            ] else ...[
              // Web: side by side if both exist, else full width
              if (categoryData.isNotEmpty && monthlyData.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPieChartCard(context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildBarChartCard(context)),
                  ],
                )
              else if (categoryData.isNotEmpty)
                _buildPieChartCard(context)
              else if (monthlyData.isNotEmpty)
                _buildBarChartCard(context),
            ],

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  // ── Pie chart card ────────────────────────────────────────────────────────────

  Widget _buildPieChartCard(BuildContext context) {
    final total = _totalCategory;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(children: [
              Icon(Icons.pie_chart_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text('Category Wise Spending', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 4),
            Text('Total: ${_fmtAmount(total)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),

            // Pie chart
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          touchedPieIndex = -1;
                        } else {
                          touchedPieIndex =
                              response.touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: List.generate(categoryData.length, (i) {
                    final item    = categoryData[i];
                    final amount  = _safeDouble(item["totalAmount"]);
                    final percent = total > 0 ? (amount / total * 100) : 0.0;
                    final isTouched = i == touchedPieIndex;
                    final color   = _pieColors[i % _pieColors.length];

                    return PieChartSectionData(
                      color: color,
                      value: amount,
                      title: isTouched ? '${percent.toStringAsFixed(1)}%' : '',
                      radius: isTouched ? 60 : 50,
                      titleStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      badgeWidget: isTouched
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
                              ),
                              child: Text(
                                item["category"] ?? "",
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            )
                          : null,
                      badgePositionPercentageOffset: 1.3,
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: List.generate(categoryData.length, (i) {
                final item   = categoryData[i];
                final amount = _safeDouble(item["totalAmount"]);
                final pct    = total > 0 ? (amount / total * 100) : 0.0;
                final color  = _pieColors[i % _pieColors.length];

                return GestureDetector(
                  onTap: () => setState(() => touchedPieIndex = i == touchedPieIndex ? -1 : i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == touchedPieIndex ? color.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item["category"] ?? "—",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('${_fmtAmount(amount)}  •  ${pct.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      ]),
                    ]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bar chart card ────────────────────────────────────────────────────────────

  Widget _buildBarChartCard(BuildContext context) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    final maxVal = monthlyData
        .map((e) => _safeDouble(e["totalAmount"]))
        .fold(0.0, (a, b) => a > b ? a : b);
    final yMax = (maxVal * 1.2).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text('Monthly Expenses', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 4),
            Text('Spending trend over months',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),

            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: yMax > 0 ? yMax : 1000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = monthlyData[group.x];
                        return BarTooltipItem(
                          '${_fmtMonth(item["month"])}\n${_fmtAmount(rod.toY)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= monthlyData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _fmtMonth(monthlyData[i]["month"]),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _fmtAmount(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(monthlyData.length, (i) {
                    final amount = _safeDouble(monthlyData[i]["totalAmount"]);
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          width: monthlyData.length > 6 ? 16 : 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Monthly summary row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: monthlyData.map((item) {
                  final amount = _safeDouble(item["totalAmount"]);
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(children: [
                      Text(_fmtMonth(item["month"]),
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      Text(_fmtAmount(amount),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────────

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

  Widget _emptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        ]),
      ),
    );
  }
}