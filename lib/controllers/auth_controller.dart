import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_signin_api.dart';

class AuthController {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? photoURL,
    bool isGoogleSignup = false,
  }) async {
    try {
      final response = await ApiService.post('/patient-users/signup', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'photoURL': photoURL,
        'isGoogleSignup': isGoogleSignup,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['requiresVerification'] == true) {
          return {
            'success': true, 
            'message': data['message'], 
            'requiresVerification': true,
            'email': email
          };
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['userId'] ?? data['user']['id']);
        await prefs.setString('user_name', data['user']['name']);
        if (data['user']['email'] != null) {
          await prefs.setString('user_email', data['user']['email']);
        }
        if (data['user']['phone'] != null) {
          await prefs.setString('user_phone', data['user']['phone']);
        }
        if (data['user']['dob'] != null) {
          await prefs.setString('user_dob', data['user']['dob']);
        }
        if (data['user']['gender'] != null) {
          await prefs.setString('user_gender', data['user']['gender']);
        }
        if (data['user']['photoURL'] != null) {
          await prefs.setString('user_photo', data['user']['photoURL']);
        }
        return {'success': true, 'message': 'Signup successful'};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Signup failed',
          'error': data['error']
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post('/patient-users/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['userId'] ?? data['user']['id']);
        await prefs.setString('user_name', data['user']['name']);
        if (data['user']['email'] != null) {
          await prefs.setString('user_email', data['user']['email']);
        }
        if (data['user']['phone'] != null) {
          await prefs.setString('user_phone', data['user']['phone']);
        }
        if (data['user']['dob'] != null) {
          await prefs.setString('user_dob', data['user']['dob']);
        }
        if (data['user']['gender'] != null) {
          await prefs.setString('user_gender', data['user']['gender']);
        }
        if (data['user']['photoURL'] != null) {
          await prefs.setString('user_photo', data['user']['photoURL']);
        }
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Login failed', 
          'error': data['error'], // e.g. USER_NOT_FOUND
          'requiresVerification': data['requiresVerification'] == true,
          'email': email
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await ApiService.post('/patient-users/verify-otp', {
        'email': email,
        'otp': otp,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['userId'] ?? data['user']['id']);
        await prefs.setString('user_name', data['user']['name']);
        if (data['user']['email'] != null) {
          await prefs.setString('user_email', data['user']['email']);
        }
        if (data['user']['phone'] != null) {
          await prefs.setString('user_phone', data['user']['phone']);
        }
        if (data['user']['dob'] != null) {
          await prefs.setString('user_dob', data['user']['dob']);
        }
        if (data['user']['gender'] != null) {
          await prefs.setString('user_gender', data['user']['gender']);
        }
        if (data['user']['photoURL'] != null) {
          await prefs.setString('user_photo', data['user']['photoURL']);
        }
        return {'success': true, 'message': 'Verification successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await ApiService.post('/patient-users/resend-otp', {
        'email': email,
      });
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> googleLogin() async {
    try {
      final auth = _auth;
      if (auth == null) {
        return {
          'success': false, 
          'message': 'Google Login is currently unavailable. Please ensure google-services.json is added to the project.'
        };
      }

      final user = await GoogleSignInApi.login();
      if (user == null) return {'success': false, 'message': 'Google Sign-In cancelled'};

      final googleAuth = await user.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return {'success': false, 'message': 'Firebase error'};

      final response = await ApiService.post('/patient-users/login', {
        'email': firebaseUser.email,
        'isGoogleLogin': true,
        'photoURL': firebaseUser.photoURL,
        'name': firebaseUser.displayName,
      });

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['userId'] ?? data['user']['id']);
        await prefs.setString('user_name', data['user']['name']);
        if (data['user']['email'] != null) {
          await prefs.setString('user_email', data['user']['email']);
        }
        if (data['user']['phone'] != null) {
          await prefs.setString('user_phone', data['user']['phone']);
        }
        if (data['user']['dob'] != null) {
          await prefs.setString('user_dob', data['user']['dob']);
        }
        if (data['user']['gender'] != null) {
          await prefs.setString('user_gender', data['user']['gender']);
        }
        await prefs.setString('user_photo', firebaseUser.photoURL ?? '');
        return {'success': true};
      } else if (response.statusCode == 404 || data['error'] == 'USER_NOT_FOUND') {
        return {
          'success': false, 
          'error': 'not_found', 
          'email': firebaseUser.email, 
          'name': firebaseUser.displayName,
          'photoURL': firebaseUser.photoURL
        };
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Login failed',
          'error': data['error']
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    await GoogleSignInApi.logout();
    try {
      await _auth?.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await ApiService.forgotPassword(email);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    try {
      final response = await ApiService.verifyResetOtp(email, otp);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'resetToken': data['resetToken'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String resetToken, String newPassword) async {
    try {
      final response = await ApiService.resetPassword(email, resetToken, newPassword);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && (data['success'] == true),
        'message': data['message'] ?? 'Failed to reset password',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
