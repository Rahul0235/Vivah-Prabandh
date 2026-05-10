import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class VendorApprovalPage extends StatefulWidget {
  const VendorApprovalPage({super.key});

  @override
  State<VendorApprovalPage> createState() => _VendorApprovalPageState();
}

class _VendorApprovalPageState extends State<VendorApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // All vendors fetched once, filtered client-side
  List<dynamic> allVendors    = [];
  bool isLoading = true;

  // Filtered lists
  List<dynamic> get pendingVendors  => allVendors.where((v) => v["status"] == "PENDING").toList();
  List<dynamic> get approvedVendors => allVendors.where((v) => v["status"] == "APPROVED").toList();
  List<dynamic> get rejectedVendors => allVendors.where((v) => v["status"] == "REJECTED").toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadVendors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadVendors() async {
    try {
      final data = await ApiService.getAllVendorsForAdmin();
      setState(() {
        allVendors = data;
        isLoading  = false;
      });
    } catch (e) {
      print("VENDOR APPROVAL ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> approveVendor(int id) async {
    try {
      await ApiService.approveVendor(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vendor approved successfully"),
          backgroundColor: Colors.green,
        ),
      );
      loadVendors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> rejectVendor(int id) async {
    try {
      await ApiService.rejectVendor(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vendor rejected"),
          backgroundColor: Colors.orange,
        ),
      );
      loadVendors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showVendorDetails(BuildContext context, Map<String, dynamic> vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.store,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(vendor["name"] ?? "Vendor",
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(context, Icons.category,       "Category", vendor["category"]),
              _detailRow(context, Icons.location_on,    "Location", vendor["location"]),
              _detailRow(context, Icons.email,          "Email",    vendor["email"]),
              _detailRow(context, Icons.phone,          "Contact",  vendor["contact"]),
              _detailRow(context, Icons.currency_rupee, "Price",    vendor["price"]?.toString()),
              _detailRow(context, Icons.design_services,"Services", vendor["services"]),
              _detailRow(context, Icons.info,           "Status",   vendor["status"]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (vendor["status"] == "PENDING") ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                rejectVendor(vendor["id"]);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text("Reject"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                approveVendor(vendor["id"]);
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text("Approve"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(value ?? "—", style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendor Approvals',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Review and manage vendor registrations',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Summary Cards ──────────────────────────────────────────
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
                    _buildSummaryCard(context, 'Pending',
                        pendingVendors.length,  Colors.orange, Icons.hourglass_empty),
                    _buildSummaryCard(context, 'Approved',
                        approvedVendors.length, Colors.green,  Icons.check_circle),
                    _buildSummaryCard(context, 'Rejected',
                        rejectedVendors.length, Colors.red,    Icons.cancel),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // ── Tabs ───────────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Pending"),
                        const SizedBox(width: 6),
                        _buildTabBadge(context, pendingVendors.length, Colors.orange),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Approved"),
                        const SizedBox(width: 6),
                        _buildTabBadge(context, approvedVendors.length, Colors.green),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Rejected"),
                        const SizedBox(width: 6),
                        _buildTabBadge(context, rejectedVendors.length, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Tab Content ─────────────────────────────────────────────────────
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVendorList(pendingVendors,  showActions: true),
                    _buildVendorList(approvedVendors, showActions: false),
                    _buildVendorList(rejectedVendors, showActions: false),
                  ],
                ),
        ),
      ],
    );
  }

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
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: color),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBadge(BuildContext context, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildVendorList(List<dynamic> vendors, {required bool showActions}) {
    if (vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No vendors found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadVendors,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index] as Map<String, dynamic>;
          return _buildVendorCard(context, vendor, showActions: showActions);
        },
      ),
    );
  }

  Widget _buildVendorCard(
    BuildContext context,
    Map<String, dynamic> vendor, {
    required bool showActions,
  }) {
    final status = vendor["status"] ?? "PENDING";
    final Color statusColor = status == "APPROVED"
        ? Colors.green
        : status == "REJECTED"
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (vendor["name"] ?? "V")[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor["name"] ?? "—",
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category,
                              size: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(vendor["category"] ?? "—",
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Info Row ──────────────────────────────────────────────────
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoChip(context, Icons.location_on,    vendor["location"] ?? "—"),
                _infoChip(context, Icons.email,          vendor["email"]    ?? "—"),
                _infoChip(context, Icons.phone,          vendor["contact"]  ?? "—"),
                _infoChip(context, Icons.currency_rupee, vendor["price"]?.toString() ?? "—"),
              ],
            ),

            const SizedBox(height: 12),

            // ── Action Buttons ────────────────────────────────────────────
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showVendorDetails(context, vendor),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text("View Details"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.4)),
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => rejectVendor(vendor["id"]),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => approveVendor(vendor["id"]),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}