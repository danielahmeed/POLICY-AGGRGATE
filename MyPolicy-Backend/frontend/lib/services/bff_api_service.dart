import 'package:http/http.dart' as http;
import 'dart:convert';

/// API service for all backend BFF calls
/// Base URL: http://localhost:8090/api/bff
/// (or configured via environment)
class BffApiService {
  static const String baseUrl = 'http://localhost:8090/api/bff';
  static const String frontendBaseUrl = '$baseUrl/frontend';
  static const String timeout = '30000'; // ms

  // ──────────────────────────────────────────────────────────────
  // Auth & Signup
  // ──────────────────────────────────────────────────────────────

  /// POST /login
  static Future<Map<String, dynamic>> login({
    required String customerId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = {
      'customerIdOrUserId': customerId,
      'password': password,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// POST /signup
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String mobileNumber,
    required String dob,
  }) async {
    final url = Uri.parse('$baseUrl/signup');
    final body = {
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'dob': dob,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Signup failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Signup error: $e');
    }
  }

  /// POST /signup/verify-otp
  static Future<Map<String, dynamic>> verifySignupOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/signup/verify-otp');
    final body = {'mobileNumber': mobileNumber, 'otp': otp};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('OTP verification failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  /// POST /signup/create-password
  static Future<Map<String, dynamic>> createPassword({
    required String customerId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/signup/create-password');
    final body = {'customerId': customerId, 'password': password};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Create password failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Create password error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Recovery Flow
  // ──────────────────────────────────────────────────────────────

  /// POST /recovery/verify
  static Future<Map<String, dynamic>> verifyRecoveryIdentity({
    String? identifier, // customerIdOrEmailOrMobile
    String? customerIdOrEmailOrMobile,
    String? destination,
  }) async {
    final url = Uri.parse('$baseUrl/recovery/verify');
    final resolvedIdentifier = (customerIdOrEmailOrMobile ?? identifier ?? '').trim();
    if (resolvedIdentifier.isEmpty) {
      throw Exception('Recovery verification error: identifier is required');
    }

    final body = <String, dynamic>{
      'customerIdOrEmailOrMobile': resolvedIdentifier,
    };
    if (destination != null && destination.isNotEmpty) {
      body['destination'] = destination;
    }

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Recovery verification failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Recovery verification error: $e');
    }
  }

  /// POST /recovery/otp/verify
  static Future<Map<String, dynamic>> verifyRecoveryOtp({
    required String customerId,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/recovery/otp/verify');
    final body = {'customerId': customerId, 'otp': otp};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Recovery OTP verification failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Recovery OTP verification error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Dashboard & Analytics
  // ──────────────────────────────────────────────────────────────

  /// GET /dashboard/{customerId}
  static Future<Map<String, dynamic>> getDashboard({
    required String customerId,
  }) async {
    final url = Uri.parse('$baseUrl/portfolio/$customerId');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Get dashboard failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get dashboard error: $e');
    }
  }

  /// GET /analytics/{customerId}
  static Future<Map<String, dynamic>> getAnalytics({
    required String customerId,
  }) async {
    try {
      final insightsUrl = Uri.parse('$baseUrl/insights/$customerId');
      final insightsResponse = await http
          .get(
            insightsUrl,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (insightsResponse.statusCode != 200) {
        throw Exception('Get analytics failed: ${insightsResponse.statusCode}');
      }

      final insightsData = jsonDecode(insightsResponse.body);

      // Advisory may be unavailable depending on backend version; keep it optional.
      dynamic advisoryData;
      try {
        final advisoryUrl = Uri.parse('$baseUrl/advisory/$customerId');
        final advisoryResponse = await http
            .get(
              advisoryUrl,
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 30));
        if (advisoryResponse.statusCode == 200) {
          advisoryData = jsonDecode(advisoryResponse.body);
        }
      } catch (_) {
        advisoryData = null;
      }

      return {
        'analytics': {
          'insights': insightsData,
          'advisory': advisoryData,
        }
      };
    } catch (e) {
      throw Exception('Get analytics error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Profile
  // ──────────────────────────────────────────────────────────────

  /// GET /profile/{customerId}
  static Future<Map<String, dynamic>> getProfile({
    required String customerId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/customer/$customerId');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;
        final normalized = {
          'customerId': raw['customerId']?.toString() ?? customerId,
          'name': (raw['firstName'] ?? raw['name'] ?? '').toString(),
          'email': (raw['email'] ?? '').toString(),
          'phone': (raw['mobileNumber'] ?? raw['phone'] ?? '').toString(),
          'dateOfBirth': (raw['dateOfBirth'] ?? 'N/A').toString(),
          'gender': (raw['gender'] ?? 'N/A').toString(),
          'communicationAddress': (raw['communicationAddress'] ?? 'N/A').toString(),
          'permanentAddress': (raw['permanentAddress'] ?? 'N/A').toString(),
          'pan': (raw['pan'] ?? raw['panNumber'] ?? 'N/A').toString(),
          'aadhaar': (raw['aadhaar'] ?? 'N/A').toString(),
          'kycStatus': (raw['kycStatus'] ?? raw['status'] ?? 'Pending').toString(),
        };
        return {'customer': normalized};
      } else {
        throw Exception('Get profile failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get profile error: $e');
    }
  }

  /// PUT /profile/{customerId}
  static Future<Map<String, dynamic>> updateProfile({
    required String customerId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/auth/customer/$customerId');

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Update profile failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Update profile error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Policies & Documents
  // ──────────────────────────────────────────────────────────────

  /// GET /documents/{customerId}
  static Future<List<dynamic>> getDocuments({
    required String customerId,
  }) async {
    final url = Uri.parse('$frontendBaseUrl/documents/$customerId');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Get documents failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get documents error: $e');
    }
  }

  /// GET /policies/{customerId}
  static Future<List<dynamic>> getPolicies(String customerId) async {
    final url = Uri.parse('$frontendBaseUrl/policies/$customerId');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Get policies failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get policies error: $e');
    }
  }

  /// GET /policies/{customerId}/{policyId}
  static Future<Map<String, dynamic>> getPolicyDetail({
    required String customerId,
    required String policyId,
  }) async {
    final url = Uri.parse('$frontendBaseUrl/policies/$customerId/$policyId');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Get policy detail failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get policy detail error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Help & FAQ
  // ──────────────────────────────────────────────────────────────

  /// GET /help/faqs
  static Future<Map<String, dynamic>> getFaqs({
    String? customerId,
  }) async {
    return {
      'faqs': [
        {
          'question': 'How can I reset my password?',
          'answer': 'Use Forgot Password on login, verify OTP, then set a new password.'
        },
        {
          'question': 'Where can I find my policy documents?',
          'answer': 'Open Help > Documents & Certificates to view available policy documents.'
        },
        {
          'question': 'How do I contact support?',
          'answer': 'Open Get Help and select Raise Support Ticket for assistance.'
        }
      ]
    };
  }

  /// GET /help/actions
  static Future<Map<String, dynamic>> getHelpActions({
    String? customerId,
  }) async {
    return {
      'helpActions': [
        {'type': 'faq', 'title': 'FAQs / Help Center'},
        {'type': 'document', 'title': 'Documents & Certificates'},
        {'type': 'claim', 'title': 'File a Claim'},
        {'type': 'support', 'title': 'Raise Support Ticket'},
        {'type': 'payment', 'title': 'Payment Assistance'},
      ]
    };
  }
}
