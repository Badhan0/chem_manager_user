import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚡ IMPORTANT ⚡
  // Emulator: Use "http://10.0.2.2:5000/api"
  // Physical Device: Use your PC IP (e.g. "http://192.168.1.18:5000/api")
  static const String baseUrl = "http://192.168.1.18:5000/api";
  //static const String baseUrl = "https://chem-manager-backend-zxlh.onrender.com/api";

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

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = Uri.parse('$baseUrl$endpoint');
    print('🚀 [API PATCH] $url');
    print('🔑 Using Token: ${token != null ? "YES" : "NO"}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      
      print('✅ [API PATCH] Success (${response.statusCode})');
      return response;
    } catch (e) {
      print('❌ [API PATCH] FAILED: $e');
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

  static Future<http.Response> getDoctorClinics(String doctorId) async {
    return await get('/directory/doctors/$doctorId/clinics');
  }

  static Future<http.Response> getClinicDoctors(String clinicId) async {
    return await get('/directory/clinics/$clinicId/doctors');
  }

  static Future<http.Response> createBooking(Map<String, dynamic> bookingData) async {
    return await post('/patients', bookingData);
  }

  static Future<http.Response> updateBookingPayment(String bookingId, String status) async {
    return await patch('/patients/$bookingId', {
      'paymentStatus': status,
      'paymentMode': 'online'
    });
  }

  static Future<http.Response> getBookings({String? phone}) async {
    String query = '/patients?populate=true';
    if (phone != null) {
      query += '&phone=${Uri.encodeComponent(phone)}';
    }
    return await get(query);
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> profileData) async {
    return await post('/patient-users/update-profile', profileData);
  }

  static Future<http.Response> getProfile() async {
    return await get('/patient-users/profile');
  }

  static Future<http.Response> getOrders(String phone) async {
    return await get('/patient-users/orders?phone=${Uri.encodeComponent(phone)}');
  }

  static Future<http.Response> getPrescriptions(String phone) async {
    return await get('/patient-users/prescriptions?phone=${Uri.encodeComponent(phone)}');
  }

  static Future<http.Response> getMyClinicians(String phone) async {
    return await get('/patient-users/my-clinicians?phone=${Uri.encodeComponent(phone)}');
  }

  static Future<http.Response> getAlerts(String phone) async {
    return await get('/patient-users/alerts?phone=${Uri.encodeComponent(phone)}');
  }

  static Future<http.Response> getSlotOccupancy(String doctorId, String clinicId, String date) async {
    return await get('/directory/slot-occupancy?doctorId=${Uri.encodeComponent(doctorId)}&orgId=${Uri.encodeComponent(clinicId)}&date=${Uri.encodeComponent(date)}');
  }

  static Future<http.Response> forgotPassword(String email) async {
    return await post('/patient-users/forgot-password', {'email': email});
  }

  static Future<http.Response> verifyResetOtp(String email, String otp) async {
    return await post('/patient-users/verify-reset-otp', {'email': email, 'otp': otp});
  }

  static Future<http.Response> resetPassword(String email, String resetToken, String newPassword) async {
    return await post('/patient-users/reset-password', {
      'email': email,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }
}
