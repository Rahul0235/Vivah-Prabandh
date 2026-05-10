import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  final UserModel user;

  const NotificationsPage({super.key, required this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> allNotifications = [];
  bool isLoading = true;

  // Filtered lists
  List<dynamic> get upcomingNotifications =>
      allNotifications.where((n) => n["type"] == "UPCOMING").toList();
  List<dynamic> get overdueNotifications =>
      allNotifications.where((n) => n["type"] == "OVERDUE").toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    try {
      final data = await ApiService.getNotifications(widget.user.id);
      setState(() {
        allNotifications = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "—";
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour   = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // ── No Scaffold — embeds inline inside dashboard ──────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Your reminder and alert history',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Summary Cards ───────────────────────────────────────────────
              LayoutBuilder(builder: (context, constraints) {
                final count = constraints.maxWidth > 600 ? 3 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: count,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: [
                    _buildSummaryCard(context, 'Total',    allNotifications.length,    Colors.blue,   Icons.notifications_outlined),
                    _buildSummaryCard(context, 'Upcoming', upcomingNotifications.length, Colors.orange, Icons.alarm_outlined),
                    _buildSummaryCard(context, 'Overdue',  overdueNotifications.length,  Colors.red,    Icons.warning_amber_outlined),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // ── Tabs ────────────────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text("All"),
                    const SizedBox(width: 6),
                    _buildBadge(context, allNotifications.length, Colors.blue),
                  ])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text("Upcoming"),
                    const SizedBox(width: 6),
                    _buildBadge(context, upcomingNotifications.length, Colors.orange),
                  ])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text("Overdue"),
                    const SizedBox(width: 6),
                    _buildBadge(context, overdueNotifications.length, Colors.red),
                  ])),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Tab Content ────────────────────────────────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(allNotifications),
                    _buildList(upcomingNotifications),
                    _buildList(overdueNotifications),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Summary card ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(BuildContext context, String label, int count,
      Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: color)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab badge ───────────────────────────────────────────────────────────────
  Widget _buildBadge(BuildContext context, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(count.toString(),
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  // ── Notification list ───────────────────────────────────────────────────────
  Widget _buildList(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No notifications found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildNotificationCard(context, items[index]),
      ),
    );
  }

  // ── Notification card ───────────────────────────────────────────────────────
  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> item) {
    final type     = item["type"] ?? "UPCOMING";
    final isOverdue = type == "OVERDUE";
    final color    = isOverdue ? Colors.red : Colors.orange;
    final icon     = isOverdue ? Icons.warning_amber_outlined : Icons.alarm_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject
                  Text(
                    item["subject"] ?? "Reminder",
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),

                  // Task title
                  if (item["taskTitle"] != null) ...[
                    Row(children: [
                      Icon(Icons.task_alt,
                          size: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item["taskTitle"],
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 13),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                  ],

                  // Recipient email
                  Row(children: [
                    Icon(Icons.email_outlined,
                        size: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item["recipientEmail"] ?? "—",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 12),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 8),

                  // Bottom row: type badge + sent time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      Row(children: [
                        Icon(Icons.schedule,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item["sentAt"]),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 11),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}