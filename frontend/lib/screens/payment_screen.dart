// screens/payment_screen.dart — Simulated payment step before booking
import 'package:flutter/material.dart';

/// Simulated payment screen — no real gateway integration.
/// Returns [true] when payment is "confirmed", null/false if user leaves.
class PaymentScreen extends StatefulWidget {
  /// Total amount to display (passed from booking screen)
  final double totalAmount;
  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Selected payment method index
  int _selectedIndex = 0;
  bool _isProcessing = false;
  bool _isSuccess    = false;

  static const List<_PaymentMethod> _methods = [
    _PaymentMethod(icon: Icons.qr_code,       label: 'UPI',                subtitle: 'GPay, PhonePe, Paytm, etc.', isCod: false),
    _PaymentMethod(icon: Icons.credit_card,   label: 'Credit / Debit Card', subtitle: 'Visa, Mastercard, RuPay',     isCod: false),
    _PaymentMethod(icon: Icons.account_balance_wallet, label: 'Wallet',    subtitle: 'SmartBike Wallet',             isCod: false),
    _PaymentMethod(icon: Icons.handshake_outlined, label: 'Cash on Delivery', subtitle: 'Pay at pickup — no processing fee', isCod: true),
  ];

  Future<void> _pay() async {
    final isCod = _methods[_selectedIndex].isCod;

    if (isCod) {
      // COD — no processing animation, confirm immediately
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate gateway delay
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess    = true;
    });

    // Auto-navigate back after showing success
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent accidental back-press during processing
      canPop: !_isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Payment Method'),
          centerTitle: true,
          automaticallyImplyLeading: !_isProcessing,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isSuccess ? _SuccessView() : _PaymentForm(
            methods:       _methods,
            selectedIndex: _selectedIndex,
            totalAmount:   widget.totalAmount,
            isProcessing:  _isProcessing,
            onSelect:      (i) => setState(() => _selectedIndex = i),
            onPay:         _pay,
          ),
        ),
      ),
    );
  }
}

// ── Payment form view ──────────────────────────────────────────
class _PaymentForm extends StatelessWidget {
  final List<_PaymentMethod> methods;
  final int     selectedIndex;
  final double  totalAmount;
  final bool    isProcessing;
  final void Function(int) onSelect;
  final VoidCallback onPay;

  const _PaymentForm({
    required this.methods,
    required this.selectedIndex,
    required this.totalAmount,
    required this.isProcessing,
    required this.onSelect,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Amount banner ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: const Color(0xFF1565C0),
          child: Column(
            children: [
              const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // ── Method list ────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            children: [
              Text('Choose payment method',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...List.generate(methods.length, (i) {
                final m        = methods[i];
                final selected = i == selectedIndex;
                return GestureDetector(
                  onTap: isProcessing ? null : () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1565C0).withOpacity(0.07)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(m.icon,
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.grey,
                            size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? const Color(0xFF1565C0)
                                        : Colors.black87,
                                  )),
                              Text(m.subtitle,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFF1565C0)),
                      ],
                    ),
                  ),
                );
              }),

              // ── Security note ─────────────────────────────────
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('100% secure simulated payment',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── Pay Now button ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isProcessing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.payment),
              label: Text(
                isProcessing ? 'Processing payment…' : 'Pay Now',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isProcessing ? null : onPay,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Success view ───────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 72),
          ),
          const SizedBox(height: 24),
          const Text('Payment Successful!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 8),
          Text('Proceeding to confirm your booking…',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Colors.green),
        ],
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────
class _PaymentMethod {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final bool     isCod;
  const _PaymentMethod(
      {required this.icon, required this.label, required this.subtitle, required this.isCod});
}
