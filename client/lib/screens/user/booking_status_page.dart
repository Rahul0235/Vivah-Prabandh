import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class BookingStatusPage extends StatefulWidget {
  final UserModel user;
  const BookingStatusPage({super.key, required this.user});

  @override
  State<BookingStatusPage> createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getUserBookings(widget.user.id);
      setState(() { allBookings = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _filtered(String status) {
    if (status == 'ALL') return allBookings;
    return allBookings.where((b) => (b["bookingStatus"] ?? "").toUpperCase() == status).toList();
  }

  int _count(String status) => status == 'ALL' ? allBookings.length
      : allBookings.where((b) => (b["bookingStatus"] ?? "").toUpperCase() == status).length;

  Color _bookingColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'CONFIRMED': return Colors.green;
      case 'REJECTED':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData _bookingIcon(String? s) {
    switch (s?.toUpperCase()) {
      case 'CONFIRMED': return Icons.check_circle;
      case 'REJECTED':  return Icons.cancel;
      default:          return Icons.hourglass_empty;
    }
  }

  Color _paymentColor(String? s) =>
      s?.toUpperCase() == 'PAID' ? Colors.green : Colors.orange;

  String _fmtDate(dynamic raw) {
    if (raw == null) return "—";
    try {
      final dt = DateTime.parse(raw.toString());
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${dt.day} ${m[dt.month]} ${dt.year}";
    } catch (_) { return raw.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking Status', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Track your vendor booking requests', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),

        // Summary chips
        if (allBookings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _chip(context, '${allBookings.length}', 'Total',     Colors.blue),
              const SizedBox(width: 8),
              _chip(context, '${_count("CONFIRMED")}', 'Confirmed', Colors.green),
              const SizedBox(width: 8),
              _chip(context, '${_count("PENDING")}',   'Pending',   Colors.orange),
              const SizedBox(width: 8),
              _chip(context, '${_count("REJECTED")}',  'Rejected',  Colors.red),
            ]),
          ),

        const SizedBox(height: 12),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.start,
            tabs: [
              _tab(context, 'All',       _count('ALL'),       Colors.blue),
              _tab(context, 'Pending',   _count('PENDING'),   Colors.orange),
              _tab(context, 'Confirmed', _count('CONFIRMED'), Colors.green),
              _tab(context, 'Rejected',  _count('REJECTED'),  Colors.red),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(context, _filtered('ALL')),
                    _buildList(context, _filtered('PENDING')),
                    _buildList(context, _filtered('CONFIRMED')),
                    _buildList(context, _filtered('REJECTED')),
                  ],
                ),
        ),
      ],
    );
  }

  Tab _tab(BuildContext context, String label, int count, Color color) {
    return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ),
    ]));
  }

  Widget _buildList(BuildContext context, List<dynamic> bookings) {
    if (bookings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('No bookings in this category', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _bookingCard(context, bookings[i]),
      ),
    );
  }

  Widget _bookingCard(BuildContext context, Map<String, dynamic> b) {
    final bStatus = b["bookingStatus"] ?? "PENDING";
    final pStatus = b["paymentStatus"] ?? "PENDING";
    final bColor  = _bookingColor(bStatus);
    final pColor  = _paymentColor(pStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Top row: event name + booking status ─────────────────────────
          Row(children: [
            Expanded(child: Text(b["eventName"] ?? "—",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: bColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_bookingIcon(bStatus), size: 12, color: bColor),
                const SizedBox(width: 5),
                Text(bStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: bColor)),
              ]),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Info rows ───────────────────────────────────────────────────
          _infoRow(context, Icons.build_outlined,         'Service',        b["service"]     ?? "—"),
          const SizedBox(height: 8),
          _infoRow(context, Icons.calendar_today_outlined,'Booking Date',   _fmtDate(b["bookingDate"])),
          const SizedBox(height: 8),
          _infoRow(context, Icons.person_outline,         'Booked By',      b["userName"]    ?? "—"),
          const SizedBox(height: 8),
          _infoRow(context, Icons.phone_outlined,         'Contact',        b["userContact"] ?? "—"),
          if (b["eventLocation"] != null && (b["eventLocation"] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(context, Icons.location_on_outlined, 'Location',       b["eventLocation"]),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Payment status row ───────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.payment_outlined, size: 16, color: pColor),
              const SizedBox(width: 6),
              Text('Payment: ', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              Text(pStatus, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pColor)),
            ]),
            // Status timeline indicator
            _statusTimeline(context, bStatus),
          ]),
        ]),
      ),
    );
  }

  Widget _statusTimeline(BuildContext context, String status) {
    final steps  = ['PENDING', 'CONFIRMED', 'PAID'];
    final stepIdx = status == 'REJECTED'
        ? -1
        : steps.indexOf(status.toUpperCase());

    if (status.toUpperCase() == 'REJECTED') {
      return Row(children: [
        const Icon(Icons.cancel, size: 14, color: Colors.red),
        const SizedBox(width: 4),
        const Text('Rejected', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
      ]);
    }

    return Row(children: List.generate(steps.length, (i) {
      final done  = i <= stepIdx;
      final color = done ? Colors.green : Colors.grey.shade300;
      return Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        if (i < steps.length - 1)
          Container(width: 20, height: 2, color: color),
      ]);
    }));
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _chip(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
      ]),
    );
  }
}