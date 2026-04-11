// screens/user_home_screen.dart — User Home Page after Login
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _userName = 'Rider';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['name'] != null) {
      _userName = args['name'];
    }
  }

  void _logout() async {
    await ApiService.clearToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar with logout ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.directions_bike, color: Colors.white, size: 36),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          tooltip: 'Booking History',
                          onPressed: () => Navigator.pushNamed(context, '/booking-history'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Logout',
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Greeting ─────────────────────────────────
                Text(
                  'Hi $_userName 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rent a bike in Pune and explore the city easily!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // ── Banner Card ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.motorcycle, size: 64, color: Color(0xFF1565C0)),
                      const SizedBox(height: 16),
                      const Text(
                        'Find the perfect bike for your ride',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your rental time and browse bikes available near you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search, size: 22),
                          label: const Text('BOOK NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/select-rental-time'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // ── Quick Browse Link ────────────────────────
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.list_alt, color: Colors.white70),
                    label: const Text('Browse all bikes', style: TextStyle(color: Colors.white70)),
                    onPressed: () => Navigator.pushNamed(context, '/bikes'),
                  ),
                ),
                const SizedBox(height: 4),
                // ── View Requirements Link ───────────────────
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.checklist_rtl, color: Colors.white70),
                    label: const Text('View Requirements', style: TextStyle(color: Colors.white70)),
                    onPressed: () => Navigator.pushNamed(context, '/requirements'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
