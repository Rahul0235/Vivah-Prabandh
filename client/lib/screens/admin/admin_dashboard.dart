import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';
import 'vendor_approval_page.dart';
import '../../core/common/settings_page.dart';
import '../../core/common/profile_page.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
      final data = await ApiService.getAdminDashboard();
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
        return _AdminHomeScreen(user: widget.user, dashboardData: dashboardData);
      case 'vendor_approval':
        return const VendorApprovalPage();
      case 'profile':
        return ProfilePage(user: widget.user);
      case 'settings':
        return SettingsPage(user: widget.user);
      default:
        return _AdminHomeScreen(user: widget.user, dashboardData: dashboardData);
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
            const Text('Vivah Prabandh - Admin'),
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
                child: const Icon(Icons.admin_panel_settings, color: Colors.white),
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
          _buildNavItem('dashboard',       Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem('vendor_approval', Icons.approval_outlined,  'Vendor Approval'),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, size: 30, color: Color(0xFFB76E79))),
                SizedBox(height: 12),
                Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('System Administrator', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _buildNavItem('dashboard',       Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem('vendor_approval', Icons.approval_outlined,  'Vendor Approval'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String route, IconData icon, String title) {
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

class _AdminHomeScreen extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic>? dashboardData;
  const _AdminHomeScreen({required this.user, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final totalUsers     = dashboardData?["totalUsers"]?.toString()     ?? "0";
    final totalVendors   = dashboardData?["totalVendors"]?.toString()   ?? "0";
    final totalBookings  = dashboardData?["totalBookings"]?.toString()  ?? "0";
    final totalTasks     = dashboardData?["totalTasks"]?.toString()     ?? "0";
    final pendingVendors = dashboardData?["pendingVendors"]?.toString() ?? "0";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('System overview and management', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 768 ? 5 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(context, 'Total Users',     totalUsers,     Icons.people,          Colors.blue),
                _buildStatCard(context, 'Total Vendors',   totalVendors,   Icons.store,           Colors.purple),
                _buildStatCard(context, 'Total Bookings',  totalBookings,  Icons.book_online,     Colors.green),
                _buildStatCard(context, 'Total Tasks',     totalTasks,     Icons.task_alt,        Colors.orange),
                _buildStatCard(context, 'Pending Vendors', pendingVendors, Icons.pending_actions, Colors.red),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ],
        ),
      ),
    );
  }
}