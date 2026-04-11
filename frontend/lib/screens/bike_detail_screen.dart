// screens/bike_detail_screen.dart — Bike info + recommendation + Book Now
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/recommendation_service.dart';

class BikeDetailScreen extends StatelessWidget {
  const BikeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Bike data is passed as route arguments from BikeListScreen
    final bike = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Build recommendation tip based on bike data
    final tip = RecommendationService.getTip(bike);

    // If bike came from Available Bikes screen it already passed the server-side
    // time-overlap check — treat it as available regardless of the boolean flag.
    final bool hasTimeContext = bike.containsKey('selected_start_time');
    final bool isAvailable   = hasTimeContext || bike['availability'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(bike['model'] ?? 'Bike Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──────────────────────────────────
            SizedBox(
              height: 240,
              width: double.infinity,
              child: bike['image_url'] != null
                ? CachedNetworkImage(
                    imageUrl: bike['image_url'],
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _PlaceholderImage(),
                  )
                : const _PlaceholderImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + availability ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(bike['model'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      _Badge(
                        label: isAvailable ? 'Available' : 'Booked',
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Type & Location ──────────────────────
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(bike['bike_type'] ?? 'N/A', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(bike['location'] ?? 'N/A',
                        style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // ── Specs ────────────────────────────────
                  const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _SpecRow(icon: Icons.speed, label: 'Engine', value: '${bike['engine_cc'] ?? "N/A"} CC'),
                  _SpecRow(icon: Icons.timer_outlined, label: 'Price/Hour', value: '₹${bike['price_per_hour']}'),
                  _SpecRow(icon: Icons.calendar_today_outlined, label: 'Price/Day', value: '₹${bike['price_per_day']}'),
                  _SpecRow(icon: Icons.store_outlined, label: 'Vendor', value: bike['vendor_name'] ?? 'N/A'),
                  _SpecRow(icon: Icons.location_city_outlined, label: 'Vendor Address', value: bike['vendor_address'] ?? 'N/A'),
                  const Divider(),

                  // ── Recommendation tip ───────────────────
                  if (tip != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip, style: const TextStyle(color: Colors.black87))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Book Now button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Book Now', style: TextStyle(fontSize: 16)),
                      onPressed: isAvailable
                        ? () => Navigator.pushNamed(context, '/booking', arguments: bike)
                        : null,
                    ),
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

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey.shade200,
    child: const Center(child: Icon(Icons.directions_bike, size: 80, color: Colors.grey)),
  );
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
  );
}
