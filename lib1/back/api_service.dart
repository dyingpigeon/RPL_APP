import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // static const String baseUrl = 'http://192.168.18.21:8000/api/v1';
  // static const String baseUrl = 'http://192.168.18.11:8000/api/v1';
  static const String baseUrl = 'http://10.0.2.2:8000/api/v2';
  // static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  // Helper POST request
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, String> body, {String? token}) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    print('🌐 API POST: $url');
    print('📤 Request Body: $body');
    print('🔑 Token: ${token != null ? "Yes" : "No"}');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"},
        body: jsonEncode(body),
      );

      print('📡 POST Response Status: ${response.statusCode}');
      print('📦 POST Response Headers: ${response.headers}');
      print('📄 POST Response Body: ${response.body}');

      // Cek jika response bukan JSON - FIXED NULL CHECK
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        print('⚠️ POST Response is not JSON');
        return {
          "statusCode": response.statusCode,
          "data": {"message": "Server returned non-JSON response"},
        };
      }

      final responseData = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 POST API Error: $e');
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Helper GET request dengan support query parameters
  static Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final String? finalToken = token ?? await AuthService.getToken();

    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse("$baseUrl/$endpoint").replace(queryParameters: queryParams);
    } else {
      url = Uri.parse("$baseUrl/$endpoint");
    }

    print('🌐 API GET: $url');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (queryParams != null && queryParams.isNotEmpty) {
      print('🔍 Query Params: $queryParams');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (finalToken != null && finalToken.isNotEmpty) "Authorization": "Bearer $finalToken",
        },
      );

      print('📡 GET Response Status: ${response.statusCode}');
      print('📦 GET Response Headers: ${response.headers}');

      // Print body hanya jika tidak terlalu panjang
      if (response.body.length < 1000) {
        print('📄 GET Response Body: ${response.body}');
      } else {
        print('📄 GET Response Body: [Too long, ${response.body.length} characters]');
      }

      // Cek jika response bukan JSON - FIXED NULL CHECK
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        print('⚠️ GET Response is not JSON. Content-Type: $contentType');
        print(
          '🔍 First 200 chars of response: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}',
        );

        return {
          "statusCode": response.statusCode,
          "data": {
            "message": "Server returned non-JSON response",
            "content_type": contentType,
            "body_preview": response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body,
          },
        };
      }

      final responseData = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 GET API Error: $e');
      print('🔍 Error type: ${e.runtimeType}');

      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Helper PUT request
  static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, String> body, {String? token}) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    print('🌐 API PUT: $url');
    print('📤 Request Body: $body');
    print('🔑 Token: ${token != null ? "Yes" : "No"}');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"},
        body: jsonEncode(body),
      );

      print('📡 PUT Response Status: ${response.statusCode}');
      print('📦 PUT Response Headers: ${response.headers}');
      print('📄 PUT Response Body: ${response.body}');

      // Cek jika response bukan JSON - FIXED NULL CHECK
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        print('⚠️ PUT Response is not JSON');
        return {
          "statusCode": response.statusCode,
          "data": {"message": "Server returned non-JSON response"},
        };
      }

      final responseData = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 PUT API Error: $e');
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Helper DELETE request
  static Future<Map<String, dynamic>> deleteRequest(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final String? finalToken = token ?? await AuthService.getToken();

    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse("$baseUrl/$endpoint").replace(queryParameters: queryParams);
    } else {
      url = Uri.parse("$baseUrl/$endpoint");
    }

    print('🌐 API DELETE: $url');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          if (finalToken != null && finalToken.isNotEmpty) "Authorization": "Bearer $finalToken",
        },
      );

      print('📡 DELETE Response Status: ${response.statusCode}');
      print('📦 DELETE Response Headers: ${response.headers}');
      print('📄 DELETE Response Body: ${response.body}');

      // Cek jika response bukan JSON - FIXED NULL CHECK
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        print('⚠️ DELETE Response is not JSON');
        return {
          "statusCode": response.statusCode,
          "data": {"message": "Server returned non-JSON response"},
        };
      }

      final responseData = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 DELETE API Error: $e');
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }
}
