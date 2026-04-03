import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚡ IMPORTANT ⚡
  // Emulator: Use "http://10.0.2.2:5000/api"
  // Physical Device: Use your PC IP (e.g. "http://192.168.1.18:5000/api")
  static const String baseUrl = "http://192.168.1.18:5000/api";

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = Uri.parse('$baseUrl$endpoint');
    print('🚀 [API POST] $url');
    print('🔑 Using Token: ${token != null ? "YES" : "NO"}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10)); // Fail faster if no connection
      
      print('✅ [API POST] Success (${response.statusCode})');
      return response;
    } catch (e) {
      print('❌ [API POST] FAILED: $e');
      rethrow;
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = Uri.parse('$baseUrl$endpoint');
    print('🚀 [API GET] $url');
    print('🔑 Using Token: ${token != null ? "YES" : "NO"}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('✅ [API GET] Success (${response.statusCode})');
      return response;
    } catch (e) {
      print('❌ [API GET] FAILED: $e');
      rethrow;
    }
  }

  static Future<http.Response> getDoctors({String search = "", double? lat, double? lng}) async {
    String query = '/directory/doctors?search=$search';
    if (lat != null && lng != null) {
      query += '&lat=$lat&lng=$lng';
    }
    return await get(query);
  }

  static Future<http.Response> getClinics({String search = "", double? lat, double? lng}) async {
    String query = '/directory/clinics?search=$search';
    if (lat != null && lng != null) {
      query += '&lat=$lat&lng=$lng';
    }
    return await get(query);
  }
}
