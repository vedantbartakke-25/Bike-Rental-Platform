// services/api_service.dart — Centralized HTTP client for backend API calls
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Change this to your machine's IP when testing on a physical device
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator → localhost

  static const _storage = FlutterSecureStorage();

  // ── Token helpers ────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> saveUserId(int id) async {
    await _storage.write(key: 'user_id', value: id.toString());
  }

  static Future<int?> getUserId() async {
    final val = await _storage.read(key: 'user_id');
    return val != null ? int.tryParse(val) : null;
  }

  static Future<void> clearToken() async {
    await _storage.deleteAll();
  }

  // ── Authorization header helper ──────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'password': password}),
    );
    return _handleResponse(response);
  }

  /// Login with email + password, returns JWT token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  // ────────────────────────────────────────────────────────────
  // BIKES
  // ────────────────────────────────────────────────────────────

  /// Get all bikes (no time filter — for browsing / vendor use)
  static Future<List<dynamic>> getAllBikes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['bikes'] as List<dynamic>;
  }

  /// Get bikes available for a specific time window (server-side overlap check)
  static Future<List<dynamic>> getAvailableBikes(
      String startTime, String endTime) async {
    final uri = Uri.parse('$baseUrl/bikes').replace(queryParameters: {
      'start_time': startTime,
      'end_time':   endTime,
    });
    final response = await http.get(uri, headers: await _authHeaders());
    final data = _handleResponse(response);
    return data['bikes'] as List<dynamic>;
  }

  /// Get single bike by ID
  static Future<Map<String, dynamic>> getBikeById(int bikeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes/$bikeId'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['bike'] as Map<String, dynamic>;
  }

  // ────────────────────────────────────────────────────────────
  // BOOKINGS
  // ────────────────────────────────────────────────────────────

  /// Create a new booking
  static Future<Map<String, dynamic>> createBooking({
    required int bikeId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'bike_id': bikeId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      }),
    );
    return _handleResponse(response);
  }

  /// Get bookings for a specific user
  static Future<List<dynamic>> getUserBookings(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/user/$userId'),
      headers: await _authHeaders(),
    );
    final data = _handleResponse(response);
    return data['bookings'] as List<dynamic>;
  }

  // ────────────────────────────────────────────────────────────
  // USER PROFILE & KYC
  // ────────────────────────────────────────────────────────────

  /// Get logged-in user's profile including KYC verification status
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _authHeaders(),
    );
    return _handleResponse(response);
  }

  /// Upload driving license image to backend (multipart/form-data)
  static Future<Map<String, dynamic>> uploadLicense(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final uri     = Uri.parse('$baseUrl/upload-license');
    final request = http.MultipartRequest('POST', uri);
    final token   = await getToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    // Derive MIME subtype from the file extension
    final ext     = fileName.split('.').last.toLowerCase();
    final subtype = ['png', 'gif', 'webp'].contains(ext) ? ext : 'jpeg';

    request.files.add(http.MultipartFile.fromBytes(
      'license',
      imageBytes,
      filename: fileName,
      contentType: MediaType('image', subtype),
    ));

    final streamed  = await request.send();
    final response  = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────

  /// Parse HTTP response; throw on error
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['error'] ?? 'Request failed (${response.statusCode})');
  }
}
