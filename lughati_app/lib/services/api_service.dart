// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; // غيّر IP حسب بيئتك

  static Future<Map<String, dynamic>> login(String nationalId, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      body: {
        'national_id': nationalId,
        'password': password,
      },
    );

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> completeRegistration(String nationalId, String password) async {
    final url = Uri.parse('$baseUrl/complete-registration');

    final response = await http.post(
      url,
      body: {
        'national_id': nationalId,
        'password': password,
      },
    );

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }
}
