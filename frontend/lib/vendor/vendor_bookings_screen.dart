// vendor/vendor_bookings_screen.dart — Vendor view of all bookings with ride actions
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'vendor_api_service.dart';

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final bookings = await VendorApiService.getBookings();
      if (mounted) setState(() { _bookings = bookings; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    try {
      await VendorApiService.updateBookingStatus(bookingId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking marked as $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':  return const Color(0xFF00897B); // teal
      case 'active':     return Colors.blue;
      case 'completed':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  String _statusEmoji(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':  return '✅';
      case 'active':     return '🔵';
      case 'completed':  return '🟢';
      case 'cancelled':  return '🔴';
      default:           return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Bookings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchBookings, child: const Text('Retry')),
        ],
      ));
    }
    if (_bookings.isEmpty) {
      return const Center(child: Text('No bookings found for your bikes.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _bookings.length,
      itemBuilder: (ctx, i) {
        final booking    = _bookings[i];
        final start      = DateTime.parse(booking['start_time']);
        final end        = DateTime.parse(booking['end_time']);
        final fmt        = DateFormat('dd MMM, h:mm a');
        final status     = (booking['status'] as String).toLowerCase();
        final isVerified = booking['is_verified'] == true;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Booking #${booking['booking_id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                      ),
                      child: Text(
                        '${_statusEmoji(status)} ${status.toUpperCase()}',
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // ── Details ───────────────────────────────────────
                Text('🏍  ${booking['bike_model']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('👤  ${booking['user_name']} (${booking['user_phone']})'),
                const SizedBox(height: 4),
                Text('🕐  ${fmt.format(start)} → ${fmt.format(end)}'),
                const SizedBox(height: 4),
                Text('💰  ₹${booking['total_price']}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),

                // KYC badge
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified_user : Icons.warning_amber,
                      size: 15,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'License Verified' : 'License Not Verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel — available for confirmed and active bookings
                    if (status == 'confirmed' || status == 'active') ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        onPressed: () =>
                            _updateStatus(booking['booking_id'], 'cancelled'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Start Ride — confirmed → active
                    if (status == 'confirmed')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start Ride'),
                        onPressed: () =>
                            _updateStatus(booking['booking_id'], 'active'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    // Mark Completed — active → completed
                    if (status == 'active')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Completed'),
                        onPressed: () =>
                            _updateStatus(booking['booking_id'], 'completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
