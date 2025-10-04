import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://6c9f952c8e28.ngrok-free.app/api/v1';

  // Helper POST request
  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, String> body, {
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Helper GET request
  static Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Helper PUT request
  static Future<Map<String, dynamic>> putRequest(
    String endpoint,
    Map<String, String> body, {
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }
}
