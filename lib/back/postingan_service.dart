import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

// Model untuk Postingan - dipindahkan ke level teratas
class Postingan {
  final int id;
  final int dosenId;
  final int jadwalId;
  final String caption;
  final String? imageUrl;

  Postingan({required this.id, required this.dosenId, required this.jadwalId, required this.caption, this.imageUrl});

  factory Postingan.fromJson(Map<String, dynamic> json) {
    return Postingan(
      id: json['id'],
      dosenId: json['dosenId'],
      jadwalId: json['jadwalId'],
      caption: json['caption'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'dosenId': dosenId, 'jadwalId': jadwalId, 'caption': caption, 'imageUrl': imageUrl};
  }
}

class PostinganService {
  static const String endpoint = 'postingan';

  // Validasi required parameters
  static void _validateRequiredParams({required int dosenId, required int jadwalId}) {
    if (dosenId <= 0) {
      throw ArgumentError('dosenId harus lebih besar dari 0');
    }
    if (jadwalId <= 0) {
      throw ArgumentError('jadwalId harus lebih besar dari 0');
    }
  }

  // Get semua postingan berdasarkan dosenId dan jadwalId
  static Future<List<Postingan>> getPostingan({required int dosenId, required int jadwalId}) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final response = await ApiService.getRequest(
        endpoint,
        queryParams: {'dosenId': dosenId.toString(), 'jadwalId': jadwalId.toString()},
      );

      if (response['statusCode'] == 200) {
        final data = response['data']['data'] as List;
        return data.map((json) => Postingan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load postingan: ${response['data']['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching postingan: $e');
    }
  }

  // Create new postingan
  static Future<Postingan> createPostingan({
    required int dosenId,
    required int jadwalId,
    required String caption,
    String? imageUrl,
  }) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final token = await AuthService.getToken();

      final body = {
        'dosenId': dosenId.toString(),
        'jadwalId': jadwalId.toString(),
        'caption': caption,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      final response = await ApiService.postRequest(endpoint, body, token: token);

      if (response['statusCode'] == 201 || response['statusCode'] == 200) {
        return Postingan.fromJson(response['data']['data']);
      } else {
        throw Exception('Failed to create postingan: ${response['data']['message']}');
      }
    } catch (e) {
      throw Exception('Error creating postingan: $e');
    }
  }

  // Create postingan dengan file upload (image)
  static Future<Postingan> createPostinganWithImage({
    required int dosenId,
    required int jadwalId,
    required String caption,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${ApiService.baseUrl}/$endpoint/upload');

      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Fields
      request.fields['dosenId'] = dosenId.toString();
      request.fields['jadwalId'] = jadwalId.toString();
      request.fields['caption'] = caption;

      // File
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: fileName));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Postingan.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to upload postingan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading postingan: $e');
    }
  }

  // Delete postingan by ID dengan validasi dosenId dan jadwalId
  static Future<bool> deletePostingan({required int postinganId, required int dosenId, required int jadwalId}) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${ApiService.baseUrl}/$endpoint/$postinganId');

      // Tambahkan query parameters untuk validasi
      final urlWithParams = url.replace(
        queryParameters: {'dosenId': dosenId.toString(), 'jadwalId': jadwalId.toString()},
      );

      final response = await http.delete(
        urlWithParams,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete postingan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting postingan: $e');
    }
  }

  // Update postingan dengan validasi dosenId dan jadwalId
  static Future<Postingan> updatePostingan({
    required int postinganId,
    required int dosenId,
    required int jadwalId,
    required String caption,
    String? imageUrl,
  }) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final token = await AuthService.getToken();

      final body = {
        'dosenId': dosenId.toString(),
        'jadwalId': jadwalId.toString(),
        'caption': caption,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      final response = await ApiService.putRequest('$endpoint/$postinganId', body, token: token);

      if (response['statusCode'] == 200) {
        return Postingan.fromJson(response['data']['data']);
      } else {
        throw Exception('Failed to update postingan: ${response['data']['message']}');
      }
    } catch (e) {
      throw Exception('Error updating postingan: $e');
    }
  }

  // Get postingan by ID dengan validasi dosenId dan jadwalId
  static Future<Postingan> getPostinganById({
    required int postinganId,
    required int dosenId,
    required int jadwalId,
  }) async {
    _validateRequiredParams(dosenId: dosenId, jadwalId: jadwalId);

    try {
      final response = await ApiService.getRequest(
        '$endpoint/$postinganId',
        queryParams: {'dosenId': dosenId.toString(), 'jadwalId': jadwalId.toString()},
      );

      if (response['statusCode'] == 200) {
        return Postingan.fromJson(response['data']['data']);
      } else {
        throw Exception('Failed to load postingan: ${response['data']['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching postingan: $e');
    }
  }
}
