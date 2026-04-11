// screens/select_rental_time_screen.dart — Pick start/end date+time before browsing bikes
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectRentalTimeScreen extends StatefulWidget {
  const SelectRentalTimeScreen({super.key});

  @override
  State<SelectRentalTimeScreen> createState() => _SelectRentalTimeScreenState();
}

class _SelectRentalTimeScreenState extends State<SelectRentalTimeScreen> {
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _findBikes() {
    final start = _combineDateTime(_startDate, _startTime);
    final end = _combineDateTime(_endDate, _endTime);

    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end date/time')),
      );
      return;
    }
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/available-bikes',
      arguments: {'start_time': start.toIso8601String(), 'end_time': end.toIso8601String()},
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(d);

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Select Time' : t.format(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Rental Period')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.access_time_filled, size: 48, color: Color(0xFF1565C0)),
            const SizedBox(height: 12),
            const Text(
              'When do you need a bike?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your pickup and drop-off date & time.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // ── Start Section ──────────────────────────────
            const Text('Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today,
                    label: _fmtDate(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule,
                    label: _fmtTime(_startTime),
                    onTap: () => _pickTime(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── End Section ────────────────────────────────
            const Text('End', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today,
                    label: _fmtDate(_endDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule,
                    label: _fmtTime(_endTime),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ── Find Bikes Button ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('FIND AVAILABLE BIKES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _findBikes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}
