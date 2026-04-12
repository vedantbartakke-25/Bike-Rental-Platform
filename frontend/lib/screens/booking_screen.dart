// screens/booking_screen.dart — Select start/end time and confirm booking
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'kyc_upload_screen.dart';
import 'agreement_screen.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startTime;
  DateTime? _endTime;
  bool   _isLoading = false;
  String? _error;
  double? _estimatedPrice;

  late Map<String, dynamic> _bike;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bike = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // Pre-populate rental times if coming from the new booking flow
    if (_startTime == null && _bike.containsKey('selected_start_time')) {
      _startTime = DateTime.parse(_bike['selected_start_time']);
      _endTime = DateTime.parse(_bike['selected_end_time']);
      _updatePrice();
    }
  }

  // ── Date + Time picker helper ─────────────────────────────
  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ── Recalculate estimated price ───────────────────────────
  void _updatePrice() {
    if (_startTime == null || _endTime == null || _endTime!.isBefore(_startTime!)) {
      setState(() => _estimatedPrice = null);
      return;
    }
    final hours = _endTime!.difference(_startTime!).inMinutes / 60.0;
    final days  = hours / 24;
    final price = days >= 0.5
      ? (days.ceil() * double.parse(_bike['price_per_day'].toString()))
      : (hours * double.parse(_bike['price_per_hour'].toString()));
    setState(() => _estimatedPrice = price);
  }

  Future<void> _confirmBooking() async {
    if (_startTime == null || _endTime == null) {
      setState(() => _error = 'Please select start and end time.');
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      // ── KYC CHECK: verify user before booking ─────────────────
      final profile = await ApiService.getUserProfile();
      final isVerified = profile['is_verified'] == true;
      if (!isVerified) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        // Navigate to KYC screen and await result
        final uploaded = await Navigator.pushNamed(context, '/kyc');
        if (uploaded == true) {
          // User just uploaded — auto-retry booking
          _confirmBooking();
        } else {
          setState(() => _error = 'Please upload your driving license to continue.');
        }
        return;
      }

      // ── Verified — show Rental Agreement before API call ──────
      setState(() => _isLoading = false);
      if (!mounted) return;
      final agreed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AgreementScreen()),
      );
      if (agreed != true) return; // user declined or backed out

      // ── Payment step ───────────────────────────────
      if (!mounted) return;
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            totalAmount: _estimatedPrice ?? 0.0,
          ),
        ),
      );
      if (paid != true) return; // user left payment screen

      setState(() { _isLoading = true; _error = null; });

      // ── Proceed with booking API call ─────────────────────
      await ApiService.createBooking(
        bikeId:    _bike['bike_id'],
        startTime: _startTime!,
        endTime:   _endTime!,
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Booking Confirmed! 🎉'),
            content: Text(
              'Your booking for ${_bike['model']} has been confirmed.\n\n'
              'Total: ₹${_estimatedPrice?.toStringAsFixed(2) ?? "—"}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushReplacementNamed(context, '/booking-history');
                },
                child: const Text('View Bookings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(DateTime? dt) => dt == null
    ? 'Tap to select'
    : DateFormat('dd MMM yyyy  hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${_bike['model']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bike summary card ─────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.directions_bike, size: 40, color: Color(0xFF1565C0)),
                title: Text(_bike['model'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '₹${_bike['price_per_hour']}/hr  •  ₹${_bike['price_per_day']}/day\n'
                  '${_bike['location'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Rental Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // ── Start time picker ─────────────────────────
            _TimeTile(
              label: 'Start Time',
              value: _fmt(_startTime),
              icon: Icons.play_circle_outline,
              color: Colors.green,
              onTap: () async {
                final dt = await _pickDateTime(context, initial: _startTime);
                if (dt != null) { setState(() => _startTime = dt); _updatePrice(); }
              },
            ),
            const SizedBox(height: 12),

            // ── End time picker ───────────────────────────
            _TimeTile(
              label: 'End Time',
              value: _fmt(_endTime),
              icon: Icons.stop_circle_outlined,
              color: Colors.red,
              onTap: () async {
                final dt = await _pickDateTime(context, initial: _endTime ?? _startTime);
                if (dt != null) { setState(() => _endTime = dt); _updatePrice(); }
              },
            ),
            const SizedBox(height: 20),

            // ── Price estimate ────────────────────────────
            if (_estimatedPrice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Estimated Total', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('₹${_estimatedPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),

            // ── Confirm button ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
                onPressed: _isLoading ? null : _confirmBooking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time tile widget ──────────────────────────────────────────────
class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.value,
    required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}
