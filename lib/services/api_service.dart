import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.18.21:8000/api/v2';
  //static const String baseUrl = 'https://ecd08a6c5ece.ngrok-free.app/api/v2';

  // Helper method untuk mendapatkan token dengan fallback ke AuthService
  static Future<String?> _getToken({String? token}) async {
    return token ?? await AuthService.getToken();
  }

  // Helper POST request dengan token otomatis
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, String> body, {String? token}) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final String? finalToken = await _getToken(token: token);

    print('🌐 API POST: $url');
    print('📤 Request Body: $body');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (finalToken != null) {
      print('🔐 Token Value: Bearer $finalToken');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (finalToken != null && finalToken.isNotEmpty) "Authorization": "Bearer $finalToken",
        },
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

  // Helper GET request dengan support query parameters dan token otomatis
  static Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final String? finalToken = await _getToken(token: token);

    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse("$baseUrl/$endpoint").replace(queryParameters: queryParams);
    } else {
      url = Uri.parse("$baseUrl/$endpoint");
    }

    print('🌐 API GET: $url');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (finalToken != null) {
      print('🔐 Token Value: Bearer $finalToken');
    }
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
          '🔍 First 200 chars of response: ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}',
        );

        return {
          "statusCode": response.statusCode,
          "data": {
            "message": "Server returned non-JSON response",
            "content_type": contentType,
            "body_preview": response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body,
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

  // Helper PUT request dengan token otomatis
  static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, String> body, {String? token}) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final String? finalToken = await _getToken(token: token);

    print('🌐 API PUT: $url');
    print('📤 Request Body: $body');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (finalToken != null) {
      print('🔐 Token Value: Bearer $finalToken');
    }

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (finalToken != null && finalToken.isNotEmpty) "Authorization": "Bearer $finalToken",
        },
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

  // Helper DELETE request dengan token otomatis
  static Future<Map<String, dynamic>> deleteRequest(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final String? finalToken = await _getToken(token: token);

    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      url = Uri.parse("$baseUrl/$endpoint").replace(queryParameters: queryParams);
    } else {
      url = Uri.parse("$baseUrl/$endpoint");
    }

    print('🌐 API DELETE: $url');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (finalToken != null) {
      print('🔐 Token Value: Bearer $finalToken');
    }

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

  // NEW: PATCH request dengan token otomatis
  static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final String? finalToken = await _getToken(token: token);

    print('🌐 API PATCH: $url');
    print('📤 Request Body: $body');
    print('🔑 Token: ${finalToken != null ? "Yes" : "No"}');
    if (finalToken != null) {
      print('🔐 Token Value: Bearer $finalToken');
    }

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          if (finalToken != null && finalToken.isNotEmpty) "Authorization": "Bearer $finalToken",
        },
        body: jsonEncode(body),
      );

      print('📡 PATCH Response Status: ${response.statusCode}');
      print('📦 PATCH Response Headers: ${response.headers}');
      print('📄 PATCH Response Body: ${response.body}');

      // Cek jika response bukan JSON - FIXED NULL CHECK
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        print('⚠️ PATCH Response is not JSON');
        return {
          "statusCode": response.statusCode,
          "data": {"message": "Server returned non-JSON response"},
        };
      }

      final responseData = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 PATCH API Error: $e');
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }

  // Tambahkan di api_service.dart - MULTIPART REQUEST SUPPORT
  static Future<Map<String, dynamic>> multipartRequest({
    required String endpoint,
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final String? finalToken = await _getToken();

    print('🌐 API MULTIPART: $url');
    print('📤 Request Fields: $fields');
    print('📁 File Field: $fileField, Path: $filePath');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers['Accept'] = 'application/json';
      if (finalToken != null && finalToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $finalToken';
      }

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add file
      var file = await http.MultipartFile.fromPath(fileField, filePath);
      request.files.add(file);

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📡 Multipart Response Status: ${response.statusCode}');
      print('📦 Multipart Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);
      return {"statusCode": response.statusCode, "data": responseData};
    } catch (e) {
      print('💥 Multipart API Error: $e');
      return {
        "statusCode": 500,
        "data": {"message": "Terjadi kesalahan koneksi: $e"},
      };
    }
  }
}
