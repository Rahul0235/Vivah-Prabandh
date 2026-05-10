import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/common/settings_page.dart';
import '../../core/common/profile_page.dart';
import 'vendor_booking_status_page.dart';

class VendorDashboard extends StatefulWidget {
  final UserModel user;
  const VendorDashboard({super.key, required this.user});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  String _selectedRoute = 'dashboard';

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final data = await ApiService.getVendorDashboard(widget.user.id);
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Widget _getScreen() {
    switch (_selectedRoute) {
      case 'dashboard':
        return _VendorHomeScreen(user: widget.user, dashboardData: dashboardData);
      case 'booking_status':
        return VendorBookingStatusPage(user: widget.user);
      case 'profile':
        return ProfilePage(user: widget.user);
      case 'settings':
        return SettingsPage(user: widget.user);
      default:
        return _VendorHomeScreen(user: widget.user, dashboardData: dashboardData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Vivah Prabandh'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => setState(() => _selectedRoute = 'settings'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : "V",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onPressed: () => setState(() => _selectedRoute = 'profile'),
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(child: _getScreen()),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _navItem('dashboard',      Icons.dashboard_outlined,   'Dashboard'),
          _navItem('booking_status', Icons.book_online_outlined, 'Booking Status'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.store, size: 30, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name.isNotEmpty ? widget.user.name : "Vendor",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(widget.user.category ?? 'Vendor',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _navItem('dashboard',      Icons.dashboard_outlined,   'Dashboard'),
          _navItem('booking_status', Icons.book_online_outlined, 'Booking Status'),
        ],
      ),
    );
  }

  Widget _navItem(String route, IconData icon, String title) {
    final isSelected = _selectedRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      title: Text(title, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        setState(() => _selectedRoute = route);
        if (MediaQuery.of(context).size.width < 768) Navigator.pop(context);
      },
    );
  }
}

class _VendorHomeScreen extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic>? dashboardData;
  const _VendorHomeScreen({required this.user, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final pendingBookings  = dashboardData?["pendingBookings"]?.toString() ?? "0";
    final confirmedEvents  = dashboardData?["confirmedEvents"]?.toString() ?? "0";
    final totalEarnings    = dashboardData?["totalEarnings"] != null
        ? "₹${dashboardData!["totalEarnings"].toStringAsFixed(0)}"
        : "₹0";
    final pendingList      = dashboardData?["pendingList"]      ?? [];
    final confirmedList    = dashboardData?["confirmedList"]    ?? [];
    final upcomingSchedule = dashboardData?["upcomingSchedule"] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, ${user.name}!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your vendor dashboard overview', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 768 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _statCard(context, 'Pending Bookings', pendingBookings, Icons.hourglass_empty,      Colors.orange),
                _statCard(context, 'Confirmed Events', confirmedEvents, Icons.check_circle_outline, Colors.green),
                _statCard(context, 'Total Earnings',   totalEarnings,   Icons.currency_rupee,       Theme.of(context).colorScheme.primary),
              ],
            );
          }),
          const SizedBox(height: 32),
          _section(context, 'Pending Bookings', Icons.hourglass_empty, [
            if (pendingList.isEmpty) _empty(context, 'No pending bookings')
            else ...pendingList.map<Widget>((b) => _bookingTile(context, b["title"] ?? "", b["date"] ?? "", b["amount"] ?? "", 'pending')),
          ]),
          const SizedBox(height: 24),
          _section(context, 'Confirmed Events', Icons.check_circle, [
            if (confirmedList.isEmpty) _empty(context, 'No confirmed events')
            else ...confirmedList.map<Widget>((b) => _bookingTile(context, b["title"] ?? "", b["date"] ?? "", b["amount"] ?? "", 'confirmed')),
          ]),
          const SizedBox(height: 24),
          _section(context, 'Earnings Overview', Icons.account_balance_wallet, [
            _earningRow(context, 'Total Earnings',   totalEarnings,   Theme.of(context).colorScheme.primary),
            _earningRow(context, 'Pending Bookings', pendingBookings, Colors.orange),
            _earningRow(context, 'Confirmed Events', confirmedEvents, Colors.green),
          ]),
          const SizedBox(height: 24),
          _section(context, 'Upcoming Schedule', Icons.calendar_today, [
            if (upcomingSchedule.isEmpty) _empty(context, 'No upcoming schedule')
            else ...upcomingSchedule.map<Widget>((s) => _scheduleTile(context, s["title"] ?? "", s["time"] ?? "")),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 28), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(title, style: Theme.of(context).textTheme.bodySmall)])])));
  }

  Widget _section(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Text(title, style: Theme.of(context).textTheme.titleLarge)]), const SizedBox(height: 16), ...children])));
  }

  Widget _empty(BuildContext context, String message) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text(message, style: Theme.of(context).textTheme.bodySmall)));
  }

  Widget _bookingTile(BuildContext context, String title, String date, String amount, String status) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: status == 'confirmed' ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)), child: Icon(status == 'confirmed' ? Icons.check : Icons.hourglass_empty, color: Colors.white, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 4), Text(date, style: Theme.of(context).textTheme.bodySmall)])), Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))]));
  }

  Widget _earningRow(BuildContext context, String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 10), Text(label, style: const TextStyle(fontWeight: FontWeight.w500))]), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15))]));
  }

  Widget _scheduleTile(BuildContext context, String title, String time) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 4, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(time, style: Theme.of(context).textTheme.bodySmall)]))]));
  }
}