// screens/agreement_screen.dart — Rental Agreement before booking confirmation
import 'package:flutter/material.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _agreed = false;

  static const List<_AgreementClause> _clauses = [
    _AgreementClause(
      icon: Icons.badge_outlined,
      text: 'User must carry a valid driving license at all times during the rental period.',
    ),
    _AgreementClause(
      icon: Icons.build_outlined,
      text: 'User is responsible for any damage caused to the bike during the rental period.',
    ),
    _AgreementClause(
      icon: Icons.timer_outlined,
      text: 'Late return charges may apply if the bike is not returned by the agreed end time.',
    ),
    _AgreementClause(
      icon: Icons.local_gas_station_outlined,
      text: 'Fuel must be returned at the same level as at the time of pickup.',
    ),
    _AgreementClause(
      icon: Icons.security_outlined,
      text: 'The vendor is not responsible for any accidents, injuries, or third-party liabilities.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Agreement'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.gavel, color: Color(0xFF1565C0), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Please read the following terms carefully before confirming.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Clause list
                  ...List.generate(_clauses.length, (i) {
                    final clause = _clauses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number badge
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Icon
                              Icon(clause.icon,
                                  color: Colors.grey[500], size: 20),
                              const SizedBox(width: 10),
                              // Text
                              Expanded(
                                child: Text(
                                  clause.text,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Bottom sticky section ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreed,
                          onChanged: (val) =>
                              setState(() => _agreed = val ?? false),
                          activeColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        const Expanded(
                          child: Text(
                            'I agree to the terms and conditions',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Confirm Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: _agreed
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                      foregroundColor:
                          _agreed ? Colors.white : Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: _agreed ? 3 : 0,
                    ),
                    // Disabled until agreed
                    onPressed: _agreed
                        ? () => Navigator.of(context).pop(true)
                        : null,
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

// Simple data class for each clause
class _AgreementClause {
  final IconData icon;
  final String text;
  const _AgreementClause({required this.icon, required this.text});
}
