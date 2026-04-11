// screens/available_bikes_screen.dart — Show bikes available for the selected time range
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class AvailableBikesScreen extends StatefulWidget {
  const AvailableBikesScreen({super.key});

  @override
  State<AvailableBikesScreen> createState() => _AvailableBikesScreenState();
}

class _AvailableBikesScreenState extends State<AvailableBikesScreen> {
  List<dynamic> _bikes = [];
  bool _isLoading = true;
  String? _error;

  late String _startTime;
  late String _endTime;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _startTime = args['start_time'];
      _endTime = args['end_time'];
      _isInit = true;
      _fetchBikes();
    }
  }

  Future<void> _fetchBikes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Pass times to backend — server filters by time-based availability
      final bikes = await ApiService.getAvailableBikes(_startTime, _endTime);
      setState(() { _bikes = bikes; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(_startTime);
    final end = DateTime.parse(_endTime);
    final hours = end.difference(start).inMinutes / 60.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Available Bikes')),
      body: Column(
        children: [
          // ── Time summary bar ──────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 18, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(
                  '${hours.toStringAsFixed(1)} hours rental',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ),

          // ── Bike list ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchBikes, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _bikes.isEmpty
                        ? const Center(child: Text('No bikes available for this time period.'))
                        : RefreshIndicator(
                            onRefresh: _fetchBikes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _bikes.length,
                              itemBuilder: (ctx, i) {
                                final bike = _bikes[i];
                                return _AvailableBikeCard(
                                  bike: bike,
                                  startTime: _startTime,
                                  endTime: _endTime,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AvailableBikeCard extends StatelessWidget {
  final Map<String, dynamic> bike;
  final String startTime;
  final String endTime;
  const _AvailableBikeCard({required this.bike, required this.startTime, required this.endTime});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bike image ────────────────────────────────
          SizedBox(
            height: 160,
            width: double.infinity,
            child: bike['image_url'] != null
                ? CachedNetworkImage(
                    imageUrl: bike['image_url'],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.directions_bike, size: 64, color: Colors.grey)),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.directions_bike, size: 64, color: Colors.grey)),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike['model'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InfoChip(icon: Icons.speed, label: '${bike['engine_cc'] ?? 'N/A'} CC'),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.location_on, label: bike['location'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${bike['price_per_hour']}/hr',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${bike['price_per_day']}/day',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('VIEW DETAILS'),
                    onPressed: () {
                      // Pass bike data along with the selected rental times
                      final bikeWithTime = Map<String, dynamic>.from(bike);
                      bikeWithTime['selected_start_time'] = startTime;
                      bikeWithTime['selected_end_time'] = endTime;
                      Navigator.pushNamed(context, '/bike-detail', arguments: bikeWithTime);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }
}
