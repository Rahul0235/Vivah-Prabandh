import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class VendorListPage extends StatefulWidget {
  final UserModel user;
  final void Function(Map<String, dynamic> vendor)? onVendorTap;
  const VendorListPage({super.key, required this.user, this.onVendorTap});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage> {
  String?        selectedCategory;
  List<dynamic>  vendors       = [];
  bool           isLoading     = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Catering',     'icon': Icons.restaurant_outlined,          'color': Colors.orange},
    {'label': 'Decoration',   'icon': Icons.celebration_outlined,          'color': Colors.pink},
    {'label': 'Photography',  'icon': Icons.camera_alt_outlined,           'color': Colors.blue},
    {'label': 'Videography',  'icon': Icons.videocam_outlined,             'color': Colors.indigo},
    {'label': 'Venue',        'icon': Icons.location_on_outlined,          'color': Colors.teal},
    {'label': 'DJ',           'icon': Icons.music_note_outlined,           'color': Colors.purple},
    {'label': 'Makeup',       'icon': Icons.face_retouching_natural,       'color': Colors.red},
    {'label': 'Mehendi',      'icon': Icons.palette_outlined,              'color': Colors.brown},
    {'label': 'Transport',    'icon': Icons.directions_car_outlined,       'color': Colors.cyan},
    {'label': 'Clothing',     'icon': Icons.checkroom_outlined,            'color': Colors.green},
    {'label': 'Invitation',   'icon': Icons.mail_outline,                  'color': Colors.amber},
    {'label': 'Pandit',       'icon': Icons.auto_stories_outlined,         'color': Colors.deepOrange},
  ];

  Future<void> _selectCategory(String category) async {
    setState(() { selectedCategory = category; isLoading = true; vendors = []; });
    try {
      final data = await ApiService.getVendorsByCategory(category);
      setState(() { vendors = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
    }
  }

  Color _catColor(String? cat) {
    final match = _categories.where((c) => c['label'].toString().toLowerCase() == cat?.toLowerCase()).toList();
    return match.isNotEmpty ? match.first['color'] as Color : Theme.of(context).colorScheme.primary;
  }

  IconData _catIcon(String? cat) {
    final match = _categories.where((c) => c['label'].toString().toLowerCase() == cat?.toLowerCase()).toList();
    return match.isNotEmpty ? match.first['icon'] as IconData : Icons.store_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vendors', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Browse vendors by category', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),

        // Category grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 6 : 4;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: _categories.map((cat) {
                final isSelected = selectedCategory == cat['label'];
                final color      = cat['color'] as Color;
                return InkWell(
                  onTap: () => _selectCategory(cat['label'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? color : color.withOpacity(0.25), width: isSelected ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(cat['icon'] as IconData, size: 24, color: isSelected ? Colors.white : color),
                      const SizedBox(height: 5),
                      Text(cat['label'] as String,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color),
                          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              }).toList(),
            );
          }),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),

        // Vendor list
        Expanded(
          child: selectedCategory == null
              ? _empty(context, Icons.storefront_outlined, 'Select a category to browse vendors')
              : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vendors.isEmpty
                      ? _empty(context, Icons.search_off, 'No vendors found in this category')
                      : RefreshIndicator(
                          onRefresh: () => _selectCategory(selectedCategory!),
                          child: isMobile
                              ? _mobileList(context)
                              : _webGrid(context),
                        ),
        ),
      ],
    );
  }

  Widget _mobileList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _vendorCard(context, vendors[i]),
    );
  }

  Widget _webGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.0,
        ),
        itemCount: vendors.length,
        itemBuilder: (context, i) => _vendorCard(context, vendors[i]),
      );
    });
  }

  Widget _vendorCard(BuildContext context, Map<String, dynamic> v) {
    final cat      = v["category"] ?? "";
    final color    = _catColor(cat);
    final avail    = v["available"] == true;
    final rating   = v["rating"];
    final price    = v["price"];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onVendorTap?.call(Map<String, dynamic>.from(v)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_catIcon(cat), color: color, size: 26),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(v["name"] ?? "—", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: avail ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(avail ? 'Available' : 'Busy',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: avail ? Colors.green : Colors.grey)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(v["services"] ?? "—", style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                    ],
                    Icon(Icons.location_on, size: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(v["location"] ?? "—", style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                    if (price != null)
                      Text('₹${price.toString()}', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, IconData icon, String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
      const SizedBox(height: 16),
      Text(msg, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
    ]));
  }
}