import 'package:flutter/material.dart';
import 'vendor_api_service.dart';

class VendorBikesScreen extends StatefulWidget {
  const VendorBikesScreen({super.key});

  @override
  State<VendorBikesScreen> createState() => _VendorBikesScreenState();
}

class _VendorBikesScreenState extends State<VendorBikesScreen> {
  List<dynamic> _bikes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBikes();
  }

  Future<void> _fetchBikes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bikes = await VendorApiService.getMyBikes();
      if (mounted) {
        setState(() {
          _bikes = bikes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBike(int bikeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bike'),
        content: const Text('Are you sure you want to delete this bike?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VendorApiService.deleteBike(bikeId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bike deleted')));
        _fetchBikes(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bikes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBikes),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/vendor-add-bike');
          if (result == true) {
            _fetchBikes(); // Refresh if new bike was added
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetchBikes, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_bikes.isEmpty) return const Center(child: Text('No bikes found. Try adding one!'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _bikes.length,
      itemBuilder: (ctx, i) {
        final bike = _bikes[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: bike['image_url'] != null
                ? Image.network(bike['image_url'], width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.motorcycle, size: 40))
                : const Icon(Icons.motorcycle, size: 40),
            title: Text(bike['model'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${bike['price_per_day']}/day • ${bike['location']}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.pushNamed(context, '/vendor-add-bike', arguments: bike);
                  if (result == true) _fetchBikes();
                } else if (value == 'delete') {
                  _deleteBike(bike['bike_id']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}
