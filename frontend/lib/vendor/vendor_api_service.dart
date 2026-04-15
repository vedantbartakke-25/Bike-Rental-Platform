// lib/vendor/vendor_api_service.dart — Independent HTTP client for Vendor Portal
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; // Add this for file uploads if needed, or rely on internal implementation

class VendorApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/vendor';
  static const _storage = FlutterSecureStorage();

  // ── Token management (separate from user tokens) ───────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'vendor_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'vendor_token');
  }

  static Future<void> saveVendorId(int id) async {
    await _storage.write(key: 'vendor_id', value: id.toString());
  }

  static Future<int?> getVendorId() async {
    final val = await _storage.read(key: 'vendor_id');
    return val != null ? int.tryParse(val) : null;
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: 'vendor_token');
    await _storage.delete(key: 'vendor_id');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['error'] ?? 'Request failed (${response.statusCode})');
  }

  // ── 1. AUTH ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> registerVendor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> loginVendor({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  // ── 2. BIKE MANAGEMENT ───────────────────────────────────────
  static Future<List<dynamic>> getMyBikes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['bikes'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addBike({
    required String model,
    required int engineCc,
    required double pricePerHour,
    required double pricePerDay,
    required String location,
    required String bikeType,
    List<int>? imageBytes, // e.g. from image_picker readAsBytes
    String? imageFileName,
  }) async {
    final uri = Uri.parse('$baseUrl/bikes');
    final request = http.MultipartRequest('POST', uri);
    final token = await getToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['model'] = model;
    request.fields['engine_cc'] = engineCc.toString();
    request.fields['price_per_hour'] = pricePerHour.toString();
    request.fields['price_per_day'] = pricePerDay.toString();
    request.fields['location'] = location;
    request.fields['bike_type'] = bikeType;

    if (imageBytes != null && imageFileName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFileName,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateBike(
    int bikeId, {
    required String model,
    required int engineCc,
    required double pricePerHour,
    required double pricePerDay,
    required String location,
    required String bikeType,
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    final uri = Uri.parse('$baseUrl/bikes/$bikeId');
    final request = http.MultipartRequest('PUT', uri);
    final token = await getToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['model'] = model;
    request.fields['engine_cc'] = engineCc.toString();
    request.fields['price_per_hour'] = pricePerHour.toString();
    request.fields['price_per_day'] = pricePerDay.toString();
    request.fields['location'] = location;
    request.fields['bike_type'] = bikeType;

    if (imageBytes != null && imageFileName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFileName,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<void> deleteBike(int bikeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/bikes/$bikeId'),
      headers: await _authHeaders(),
    );
    _handleResponse(response);
  }

  // ── 3. BOOKING MANAGEMENT ────────────────────────────────────
  static Future<List<dynamic>> getBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['bookings'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateBookingStatus(int bookingId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(response);
  }

  // ── 4. DASHBOARD ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['stats'] as Map<String, dynamic>;
  }
}
