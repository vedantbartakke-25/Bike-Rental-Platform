// screens/bike_list_screen.dart — Browse all available bikes
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class BikeListScreen extends StatefulWidget {
  const BikeListScreen({super.key});

  @override
  State<BikeListScreen> createState() => _BikeListScreenState();
}

class _BikeListScreenState extends State<BikeListScreen> {
  List<dynamic> _bikes   = [];
  List<dynamic> _filtered = [];
  bool   _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBikes();
  }

  Future<void> _fetchBikes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final bikes = await ApiService.getAllBikes();
      setState(() { _bikes = bikes; _filtered = bikes; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = _bikes.where((b) =>
        b['model'].toString().toLowerCase().contains(query.toLowerCase()) ||
        (b['bike_type'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
        (b['location'] ?? '').toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _logout() async {
    await ApiService.clearToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Bikes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Booking History',
            onPressed: () => Navigator.pushNamed(context, '/booking-history'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by model, type, location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Bike grid ───────────────────────────────
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchBikes, child: const Text('Retry')),
                    ],
                  ))
                : _filtered.isEmpty
                  ? Center(child: Text(_searchQuery.isEmpty
                      ? 'No bikes available.' : 'No results for "$_searchQuery"'))
                  : RefreshIndicator(
                      onRefresh: _fetchBikes,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.75,
                          crossAxisSpacing: 12, mainAxisSpacing: 12,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _BikeCard(bike: _filtered[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ── Bike Card Widget ────────────────────────────────────────────
class _BikeCard extends StatelessWidget {
  final Map<String, dynamic> bike;
  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    final bool available = bike['availability'] == true;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/bike-detail', arguments: bike),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike image
            Expanded(
              child: bike['image_url'] != null
                ? CachedNetworkImage(
                    imageUrl: bike['image_url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(Icons.directions_bike, size: 64),
                  )
                : const Center(child: Icon(Icons.directions_bike, size: 64, color: Colors.grey)),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bike['model'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('₹${bike['price_per_hour']}/hr',
                    style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: available ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      available ? 'Available' : 'Booked',
                      style: TextStyle(
                        fontSize: 11,
                        color: available ? Colors.green.shade800 : Colors.red.shade800,
                      ),
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
