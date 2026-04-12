// screens/booking_history_screen.dart — User's past and active bookings
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool   _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = await ApiService.getUserId();
      if (userId == null) throw Exception('Not logged in.');
      final bookings = await ApiService.getUserBookings(userId);
      setState(() => _bookings = bookings);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':  return const Color(0xFF00897B); // teal
      case 'approved':   return const Color(0xFF00897B); // legacy — same teal
      case 'active':     return Colors.blue;
      case 'completed':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.orange; // pending (legacy)
    }
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'confirmed':  return '✅';
      case 'approved':   return '✅'; // legacy
      case 'active':     return '🔵';
      case 'completed':  return '🟢';
      case 'cancelled':  return '🔴';
      default:           return '🟡'; // pending (legacy)
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings, tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchBookings, child: const Text('Retry')),
              ],
            ))
          : _bookings.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No bookings yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/bikes'),
                      child: const Text('Browse Bikes'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchBookings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _bookings.length,
                  itemBuilder: (ctx, i) {
                    final b = _bookings[i];
                    final status = b['status'] ?? 'pending';
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_bike, color: Color(0xFF1565C0)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(b['bike_model'] ?? 'Unknown Bike',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    '${_statusEmoji(status)} ${status.toUpperCase()}',
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(Icons.play_arrow_outlined,  'Start', _formatDate(b['start_time'])),
                            _InfoRow(Icons.stop_outlined,         'End',   _formatDate(b['end_time'])),
                            _InfoRow(Icons.currency_rupee,        'Total', '₹${b['total_price'] ?? '—'}'),
                            _InfoRow(Icons.calendar_today_outlined, 'Booked On', _formatDate(b['created_at'])),
                            if (b['bike_type'] != null)
                              _InfoRow(Icons.category_outlined, 'Bike Type', b['bike_type']),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
