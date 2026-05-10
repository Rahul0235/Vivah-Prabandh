import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class VendorDetailsPage extends StatefulWidget {
  final UserModel user;
  final dynamic vendorPreview; // basic data from list
  final void Function()? onBookNow;
  const VendorDetailsPage({super.key, required this.user, required this.vendorPreview, this.onBookNow});

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  Map<String, dynamic>? vendor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getVendorById(widget.vendorPreview["id"].toString());
      setState(() { vendor = data; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _catColor(String? cat) {
    const map = {
      'catering': Colors.orange, 'decoration': Colors.pink,
      'photography': Colors.blue, 'videography': Colors.indigo,
      'venue': Colors.teal, 'dj': Colors.purple,
      'makeup': Colors.red, 'mehendi': Colors.brown,
      'transport': Colors.cyan, 'clothing': Colors.green,
      'invitation': Colors.amber, 'pandit': Colors.deepOrange,
    };
    return map[cat?.toLowerCase()] ?? Colors.grey;
  }

  IconData _catIcon(String? cat) {
    const map = {
      'catering': Icons.restaurant_outlined, 'decoration': Icons.celebration_outlined,
      'photography': Icons.camera_alt_outlined, 'videography': Icons.videocam_outlined,
      'venue': Icons.location_on_outlined, 'dj': Icons.music_note_outlined,
      'makeup': Icons.face_retouching_natural, 'mehendi': Icons.palette_outlined,
      'transport': Icons.directions_car_outlined, 'clothing': Icons.checkroom_outlined,
      'invitation': Icons.mail_outline, 'pandit': Icons.auto_stories_outlined,
    };
    return map[cat?.toLowerCase()] ?? Icons.store_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (vendor == null) return const Center(child: Text("Vendor not found."));

    final v       = vendor!;
    final cat     = v["category"] ?? "";
    final color   = _catColor(cat);
    final avail   = v["available"] == true;
    final rating  = v["rating"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header card ─────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                      child: Icon(_catIcon(cat), color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v["name"] ?? "—", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: avail ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(avail ? Icons.check_circle : Icons.cancel, size: 12, color: avail ? Colors.green : Colors.grey),
                            const SizedBox(width: 4),
                            Text(avail ? 'Available' : 'Unavailable',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: avail ? Colors.green : Colors.grey)),
                          ]),
                        ),
                      ]),
                    ])),
                    // Rating
                    if (rating != null)
                      Column(children: [
                        Text(rating.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Row(children: List.generate(5, (i) => Icon(Icons.star,
                            size: 12,
                            color: i < (rating as num).round() ? Colors.amber : Colors.grey.shade300))),
                        const Text('Rating', style: TextStyle(fontSize: 10)),
                      ]),
                  ]),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // ── Details grid ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle(context, 'Vendor Details', Icons.info_outline),
                  const SizedBox(height: 16),
                  _detailRow(context, Icons.build_outlined,     'Services',    v["services"] ?? "—"),
                  const SizedBox(height: 14),
                  _detailRow(context, Icons.currency_rupee,     'Pricing',     v["price"] != null ? "₹${v["price"]}" : "—"),
                  const SizedBox(height: 14),
                  _detailRow(context, Icons.phone_outlined,     'Contact',     v["contact"] ?? "—"),
                  const SizedBox(height: 14),
                  _detailRow(context, Icons.email_outlined,     'Email',       v["email"] ?? "—"),
                  const SizedBox(height: 14),
                  _detailRow(context, Icons.location_on_outlined,'Location',   v["location"] ?? "—"),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            // ── Book Now button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: avail ? widget.onBookNow : null,
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: Text(avail ? 'Book This Vendor' : 'Currently Unavailable',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),

            if (!avail) ...[
              const SizedBox(height: 8),
              Center(child: Text('This vendor is currently not accepting bookings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))),
            ],

            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ])),
    ]);
  }
}