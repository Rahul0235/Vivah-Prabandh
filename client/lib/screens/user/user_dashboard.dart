import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/common/settings_page.dart';
import '../../core/common/profile_page.dart';
import 'notifications_page.dart';
import 'create_event_page.dart';
import 'event_details_page.dart';
import 'add_guest_page.dart';
import 'guest_details_page.dart';
import 'guest_list_page.dart';
import 'budget_overview_page.dart';
import 'add_expense_page.dart';
import 'expense_history_page.dart';
import 'expense_analysis_page.dart';
import 'all_tasks_page.dart';
import 'add_task_page.dart';
import 'task_details_page.dart';
import 'vendor_list_page.dart';
import 'vendor_details_page.dart';
import 'book_vendor_page.dart';
import 'booking_status_page.dart';

class UserDashboard extends StatefulWidget {
  final UserModel user;
  const UserDashboard({super.key, required this.user});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _selectedRoute = 'dashboard';
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  // Vendor navigation state — passed between list → details → book
  Map<String, dynamic>? _selectedVendor;

  final Map<String, bool> _expandedItems = {
    'events': false, 'guests': false, 'budget': false,
    'vendors': false, 'tasks': false,
  };

  @override
  void initState() { super.initState(); loadDashboard(); }

  Future<void> loadDashboard() async {
    try {
      final data = await ApiService.getUserDashboard(widget.user.id);
      setState(() { dashboardData = data; isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  Widget _getScreen() {
    switch (_selectedRoute) {
      case 'dashboard':          return _UserHomeScreen(user: widget.user, dashboardData: dashboardData);
      case 'profile':            return ProfilePage(user: widget.user);
      case 'settings':           return SettingsPage(user: widget.user);
      case 'notifications':      return NotificationsPage(user: widget.user);
      case 'events_create':      return CreateEventPage(user: widget.user, onEventCreated: loadDashboard);
      case 'events_details':     return EventDetailsPage(user: widget.user);
      case 'guests_list':        return GuestListPage(user: widget.user);
      case 'guests_add':         return AddGuestPage(user: widget.user);
      case 'guests_details':     return GuestDetailsPage(user: widget.user);
      case 'budget_overview':    return BudgetOverviewPage(user: widget.user);
      case 'budget_add_expense': return AddExpensePage(user: widget.user);
      case 'budget_history':     return ExpenseHistoryPage(user: widget.user);
      case 'budget_analysis':    return ExpenseAnalysisPage(user: widget.user);
      case 'tasks_all':          return AllTasksPage(user: widget.user);
      case 'tasks_add':          return AddTaskPage(user: widget.user);
      case 'tasks_details':      return TaskDetailsPage(user: widget.user);

      // Vendors — pass callbacks for seamless navigation
      case 'vendors_list':
        return VendorListPage(
          user: widget.user,
          onVendorTap: (vendor) => setState(() {
            _selectedVendor = vendor;
            _selectedRoute  = 'vendors_details';
          }),
        );
      case 'vendors_details':
        if (_selectedVendor == null) {
          return VendorListPage(
            user: widget.user,
            onVendorTap: (vendor) => setState(() {
              _selectedVendor = vendor;
              _selectedRoute  = 'vendors_details';
            }),
          );
        }
        return VendorDetailsPage(
          user: widget.user,
          vendorPreview: _selectedVendor!,
          onBookNow: () => setState(() => _selectedRoute = 'vendors_book'),
        );
      case 'vendors_book':
        if (_selectedVendor == null) {
          return VendorListPage(
            user: widget.user,
            onVendorTap: (vendor) => setState(() {
              _selectedVendor = vendor;
              _selectedRoute  = 'vendors_details';
            }),
          );
        }
        return BookVendorPage(user: widget.user, vendor: _selectedVendor!);
      case 'vendors_booking_status':
        return BookingStatusPage(user: widget.user);

      default: return _UserHomeScreen(user: widget.user, dashboardData: dashboardData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.favorite, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          const Text('Vivah Prabandh'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => setState(() => _selectedRoute = 'notifications')),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => setState(() => _selectedRoute = 'settings')),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "U", style: const TextStyle(color: Colors.white))),
              onPressed: () => setState(() => _selectedRoute = 'profile'),
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(children: [
        if (!isMobile) _buildSidebar(context),
        Expanded(child: _getScreen()),
      ]),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(right: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)))),
      child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: _buildNavItems(context)),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "U", style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          Text(widget.user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.user.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
      ..._buildNavItems(context),
    ]));
  }

  List<Widget> _buildNavItems(BuildContext context) {
    return [
      _nav(route: 'dashboard', icon: Icons.dashboard_outlined, title: 'Dashboard'),
      _expandable(key: 'events', icon: Icons.event_outlined, title: 'Events', children: [
        _child(route: 'events_create',  title: 'Create Event'),
        _child(route: 'events_details', title: 'Event Details'),
      ]),
      _expandable(key: 'guests', icon: Icons.people_outlined, title: 'Guests', children: [
        _child(route: 'guests_list',    title: 'Guest List'),
        _child(route: 'guests_add',     title: 'Add Guest'),
        _child(route: 'guests_details', title: 'Guest Details'),
      ]),
      _expandable(key: 'budget', icon: Icons.currency_rupee, title: 'Budget & Expense', children: [
        _child(route: 'budget_overview',    title: 'Budget Overview'),
        _child(route: 'budget_add_expense', title: 'Add Expense'),
        _child(route: 'budget_history',     title: 'Expense History'),
        _child(route: 'budget_analysis',    title: 'Expense Analysis'),
      ]),
      _expandable(key: 'vendors', icon: Icons.store_outlined, title: 'Vendors', children: [
        _child(route: 'vendors_list',           title: 'Vendor List'),
        _child(route: 'vendors_details',        title: 'Vendor Details'),
        _child(route: 'vendors_book',           title: 'Book Vendor'),
        _child(route: 'vendors_booking_status', title: 'Booking Status'),
      ]),
      _expandable(key: 'tasks', icon: Icons.task_outlined, title: 'Tasks', children: [
        _child(route: 'tasks_all',     title: 'All Tasks'),
        _child(route: 'tasks_add',     title: 'Add Task'),
        _child(route: 'tasks_details', title: 'Task Details'),
      ]),
    ];
  }

  Widget _nav({required String route, required IconData icon, required String title}) {
    final s = _selectedRoute == route;
    return ListTile(
      leading: Icon(icon, color: s ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      title: Text(title, style: TextStyle(color: s ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface, fontWeight: s ? FontWeight.w600 : FontWeight.normal)),
      selected: s, selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () { setState(() => _selectedRoute = route); if (MediaQuery.of(context).size.width < 768) Navigator.pop(context); },
    );
  }

  Widget _expandable({required String key, required IconData icon, required String title, required List<Widget> children}) {
    final isExpanded = _expandedItems[key] ?? false;
    final isGroupActive = _selectedRoute.startsWith(key);
    return Column(children: [
      ListTile(
        leading: Icon(icon, color: isGroupActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        title: Text(title, style: TextStyle(color: isGroupActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface, fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.normal)),
        trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        selected: isGroupActive,
        onTap: () => setState(() => _expandedItems[key] = !isExpanded),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Container(color: Theme.of(context).colorScheme.primary.withOpacity(0.03), child: Column(children: children)),
        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }

  Widget _child({required String route, required String title}) {
    final s = _selectedRoute == route;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: s ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
      title: Text(title, style: TextStyle(fontSize: 13, color: s ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontWeight: s ? FontWeight.w600 : FontWeight.normal)),
      selected: s, selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () { setState(() => _selectedRoute = route); if (MediaQuery.of(context).size.width < 768) Navigator.pop(context); },
    );
  }
}

class _UserHomeScreen extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic>? dashboardData;
  const _UserHomeScreen({required this.user, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final totalEvents   = dashboardData?["totalEvents"]?.toString()   ?? "0";
    final totalBudget   = dashboardData?["totalBudget"]?.toString()   ?? "0";
    final spentAmount   = dashboardData?["spentAmount"]?.toString()   ?? "0";
    final upcomingTasks = dashboardData?["upcomingTasks"]?.toString() ?? "0";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back, ${user.name}!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Here\'s your wedding planning overview', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 768 ? 4 : 2;
          return GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3,
            children: [
              _card(context, 'Total Events',   totalEvents,     Icons.event,                  Colors.blue),
              _card(context, 'Total Budget',   '₹$totalBudget', Icons.account_balance_wallet, Colors.purple),
              _card(context, 'Amount Spent',   '₹$spentAmount', Icons.currency_rupee,         Colors.green),
              _card(context, 'Upcoming Tasks', upcomingTasks,   Icons.task_alt,               Colors.orange),
            ],
          );
        }),
      ]),
    );
  }

  Widget _card(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 28),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ]),
    ])));
  }
}