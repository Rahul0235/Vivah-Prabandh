import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class VendorBookingStatusPage extends StatefulWidget {
  final UserModel user;
  const VendorBookingStatusPage({super.key, required this.user});

  @override
  State<VendorBookingStatusPage> createState() => _VendorBookingStatusPageState();
}

class _VendorBookingStatusPageState extends State<VendorBookingStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> allBookings     = [];
  bool          isLoading       = true;
  String?       loadingActionId;

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

  // ── Loaders ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      // Resolve the Vendor entity ID from the logged-in user email
      // because widget.user.id is the User table ID, not the Vendor table ID
      final vendorEntity = await ApiService.getVendorByEmail(widget.user.email);
      final vendorId = vendorEntity["id"].toString();
      final data = await ApiService.getVendorBookings(vendorId);
      setState(() { allBookings = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
      _snack("Failed to load bookings: $e", Colors.red);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _putAction(String bookingId, String action, String successMsg) async {
    setState(() => loadingActionId = bookingId);
    try {
      final token  = await ApiService.getToken();
      final headers = {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
      final url    = "${ApiConstants.baseUrl}/api/vendor-bookings/$bookingId/$action";
      final r      = await http.put(Uri.parse(url), headers: headers);
      if (r.statusCode == 200) {
        await _load();
        _snack(successMsg, action == 'reject' ? Colors.orange : Colors.green);
      } else {
        try {
          final body = jsonDecode(r.body);
          _snack(body["message"] ?? "Action failed", Colors.red);
        } catch (_) { _snack("Action failed", Colors.red); }
      }
    } catch (e) { _snack("Error: $e", Colors.red); }
    setState(() => loadingActionId = null);
  }

  Future<void> _confirmBooking(dynamic b) async {
    await _putAction(b["bookingId"].toString(), "confirm", "Booking confirmed!");
  }

  Future<void> _rejectBooking(dynamic b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Booking?'),
        content: Text('Reject booking from ${b["userName"] ?? "this customer"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _putAction(b["bookingId"].toString(), "reject", "Booking rejected.");
  }

  Future<void> _markPaid(dynamic b) async {
    await _putAction(b["bookingId"].toString(), "payment-paid", "Payment marked as paid!");
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Filter helpers ─────────────────────────────────────────────────────────────

  List<dynamic> _filtered(String status) {
    if (status == 'ALL') return allBookings;
    return allBookings.where((b) => (b["bookingStatus"] ?? "").toUpperCase() == status).toList();
  }

  int _count(String status) => status == 'ALL'
      ? allBookings.length
      : allBookings.where((b) => (b["bookingStatus"] ?? "").toUpperCase() == status).length;

  // ── Color/icon helpers ────────────────────────────────────────────────────────

  Color _bColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'CONFIRMED': return Colors.green;
      case 'REJECTED':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData _bIcon(String? s) {
    switch (s?.toUpperCase()) {
      case 'CONFIRMED': return Icons.check_circle;
      case 'REJECTED':  return Icons.cancel;
      default:          return Icons.hourglass_empty;
    }
  }

  Color _pColor(String? s) => s?.toUpperCase() == 'PAID' ? Colors.green : Colors.orange;

  String _fmtDate(dynamic raw) {
    if (raw == null) return "—";
    try {
      final dt = DateTime.parse(raw.toString());
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${dt.day} ${m[dt.month]} ${dt.year}";
    } catch (_) { return raw.toString(); }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking Status', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Manage and respond to booking requests', style: Theme.of(context).textTheme.bodyMedium),
            ])),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
              onPressed: _load,
            ),
          ]),
        ),

        // ── Summary chips ────────────────────────────────────────────────────
        if (allBookings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(context, '${allBookings.length}',  'Total',     Colors.blue),
              _chip(context, '${_count("PENDING")}',   'Pending',   Colors.orange),
              _chip(context, '${_count("CONFIRMED")}', 'Confirmed', Colors.green),
              _chip(context, '${_count("REJECTED")}',  'Rejected',  Colors.red),
            ]),
          ),

        // ── Tabs ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: Theme.of(context).colorScheme.primary,
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

  // ── Tab widget ────────────────────────────────────────────────────────────────

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

  // ── List / Grid ───────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<dynamic> bookings) {
    if (bookings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy_outlined, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('No bookings here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ]));
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    return RefreshIndicator(
      onRefresh: _load,
      child: isMobile
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _bookingCard(context, bookings[i]),
            )
          : LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 1100 ? 2 : 1;
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16,
                  childAspectRatio: cols == 2 ? 1.45 : 2.2,
                ),
                itemCount: bookings.length,
                itemBuilder: (_, i) => _bookingCard(context, bookings[i]),
              );
            }),
    );
  }

  // ── Booking card ──────────────────────────────────────────────────────────────

  Widget _bookingCard(BuildContext context, Map<String, dynamic> b) {
    final bStatus     = b["bookingStatus"] ?? "PENDING";
    final pStatus     = b["paymentStatus"] ?? "PENDING";
    final bColor      = _bColor(bStatus);
    final pColor      = _pColor(pStatus);
    final isPending   = bStatus.toUpperCase() == 'PENDING';
    final isConfirmed = bStatus.toUpperCase() == 'CONFIRMED';
    final isRejected  = bStatus.toUpperCase() == 'REJECTED';
    final isPaid      = pStatus.toUpperCase() == 'PAID';
    final id          = b["bookingId"].toString();
    final isActioning = loadingActionId == id;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bColor.withOpacity(0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Event name + status badge ──────────────────────────────────
            Row(children: [
              Expanded(
                child: Text(b["eventName"] ?? "—",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bColor.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_bIcon(bStatus), size: 13, color: bColor),
                  const SizedBox(width: 5),
                  Text(bStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: bColor)),
                ]),
              ),
            ]),

            const SizedBox(height: 14),

            // ── Booking details ────────────────────────────────────────────
            _row(context, Icons.calendar_today_outlined, 'Booking Date', _fmtDate(b["bookingDate"])),
            const SizedBox(height: 8),
            _row(context, Icons.build_outlined,           'Service',     b["service"]      ?? "—"),
            const SizedBox(height: 8),
            _row(context, Icons.person_outline,            'Customer',   b["userName"]     ?? "—"),
            const SizedBox(height: 8),
            _row(context, Icons.phone_outlined,            'Contact',    b["userContact"]  ?? "—"),
            if (b["eventLocation"] != null && (b["eventLocation"] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              _row(context, Icons.location_on_outlined,   'Location',    b["eventLocation"]),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Payment row ────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.payment_outlined, size: 15, color: pColor),
                const SizedBox(width: 6),
                Text('Payment: ', style: Theme.of(context).textTheme.bodySmall),
                Text(pStatus, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pColor)),
              ]),
              if (b["paymentMethod"] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      b["paymentMethod"].toString().toUpperCase() == 'CASH'
                          ? Icons.money_outlined : Icons.qr_code_outlined,
                      size: 12, color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(b["paymentMethod"], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                  ]),
                ),
            ]),

            const SizedBox(height: 16),

            // ── Action buttons ─────────────────────────────────────────────
            if (isPending) ...[
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isActioning ? null : () => _confirmBooking(b),
                    icon: isActioning
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isActioning ? null : () => _rejectBooking(b),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ]),
            ] else if (isConfirmed && !isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isActioning ? null : () => _markPaid(b),
                  icon: isActioning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Mark Payment as Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ] else if (isConfirmed && isPaid) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Booking Complete & Paid', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green, fontSize: 13)),
                ]),
              ),
            ] else if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.block, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Booking Rejected', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 13)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────────

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ]);
  }

  // ── Summary chip ──────────────────────────────────────────────────────────────

  Widget _chip(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
      ]),
    );
  }
}