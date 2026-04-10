// main.dart — Flutter app entry point
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/bike_list_screen.dart';
import 'screens/bike_detail_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/select_rental_time_screen.dart';
import 'screens/available_bikes_screen.dart';
import 'screens/kyc_upload_screen.dart';
import 'screens/requirements_screen.dart';
import 'screens/agreement_screen.dart';
import 'screens/payment_screen.dart';

import 'vendor/vendor_login_screen.dart';
import 'vendor/vendor_register_screen.dart';
import 'vendor/vendor_dashboard_screen.dart';
import 'vendor/add_edit_bike_screen.dart';

void main() {
  runApp(const SmartBikeRentalApp());
}

class SmartBikeRentalApp extends StatelessWidget {
  const SmartBikeRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bike Rental',
      debugShowCheckedModeBanner: false,
      // ── App Theme ──────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Deep blue primary
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      // ── Named Routes ───────────────────────────────────────
      initialRoute: '/login',
      routes: {
        '/login':              (_) => const LoginScreen(),
        '/register':           (_) => const RegisterScreen(),
        '/home':               (_) => const UserHomeScreen(),
        '/select-rental-time': (_) => const SelectRentalTimeScreen(),
        '/available-bikes':    (_) => const AvailableBikesScreen(),
        '/bikes':              (_) => const BikeListScreen(),
        '/bike-detail':        (_) => const BikeDetailScreen(),
        '/booking':            (_) => const BookingScreen(),
        '/booking-history':    (_) => const BookingHistoryScreen(),
        // ── Vendor Routes ──────────────────────────────────────
        '/vendor-login':    (_) => const VendorLoginScreen(),
        '/vendor-register': (_) => const VendorRegisterScreen(),
        '/vendor-dashboard':(_) => const VendorDashboardScreen(),
        '/vendor-add-bike': (_) => const AddEditBikeScreen(),
        '/kyc':             (_) => const KycUploadScreen(),
        '/requirements':    (_) => const RequirementsScreen(),
        '/agreement':       (_) => const AgreementScreen(),
        // Payment screen receives totalAmount via Navigator.push, not named route
        // but register it as fallback for direct navigation if ever needed
      },
    );
  }
}
