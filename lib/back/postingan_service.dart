import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

// Model untuk Postingan - disesuaikan dengan struktur API
class Postingan {
  final int id;
  final int? dosenId;
  final int? jadwalId;
  final String judul;
  final String konten;
  final String? fileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? dosen;

  Postingan({
    required this.id,
    this.dosenId,
    this.jadwalId,
    required this.judul,
    required this.konten,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
    this.dosen,
  });

  factory Postingan.fromJson(Map<String, dynamic> json) {
    print("🔧 Parsing Postingan from JSON: $json");
    
    final postingan = Postingan(
      id: json['id'] ?? 0,
      dosenId: json['dosen_id'] ?? json['dosenId'],
      jadwalId: json['jadwal_id'] ?? json['jadwalId'],
      judul: json['judul'] ?? json['title'] ?? '',
      konten: json['konten'] ?? json['content'] ?? json['caption'] ?? '',
      fileUrl: json['file_url'] ?? json['fileUrl'] ?? json['imageUrl'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'])
            : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'])
            : null,
      dosen: json['dosen'] is Map ? json['dosen'] : null,
    );
    
    print("✅ Postingan parsed: ${postingan.judul}");
    return postingan;
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'dosen_id': dosenId,
      'jadwal_id': jadwalId,
      'judul': judul,
      'konten': konten,
      'file_url': fileUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    
    print("🔧 Converting Postingan to JSON: $json");
    return json;
  }
}

class PostinganService {
  static const String endpoint = 'postingan';

  // Validasi required parameters
  static void _validateRequiredParams({required int jadwalId}) {
    print("🔍 Validating parameters - jadwalId: $jadwalId");
    if (jadwalId <= 0) {
      print("❌ Validation failed: jadwalId harus lebih besar dari 0");
      throw ArgumentError('jadwalId harus lebih besar dari 0');
    }
    print("✅ Parameters validation passed");
  }

  // Get semua postingan berdasarkan jadwalId - DISESUAIKAN
  static Future<List<Postingan>> getPostinganByJadwal({required int jadwalId}) async {
    print("🚀 START getPostinganByJadwal - jadwalId: $jadwalId");
    _validateRequiredParams(jadwalId: jadwalId);

    try {
      final List<Postingan> allPostingan = [];
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 10;

      print("🔄 Starting pagination loop for jadwalId: $jadwalId");

      while (hasMoreData && page <= maxPages) {
        print("📖 Processing page $page");
        
        final Map<String, String> queryParams = {
          'jadwal_id': jadwalId.toString(),
          'page': page.toString(),
          'per_page': '20'
        };

        print("🌐 API Call - Endpoint: $endpoint, QueryParams: $queryParams");
        final response = await ApiService.getRequest(endpoint, queryParams: queryParams);

        print("📡 API Response - Status: ${response['statusCode']}, Page: $page");

        if (response['statusCode'] == 200) {
          final data = response['data'];
          print("📊 Raw response data type: ${data.runtimeType}");
          print("📊 Raw response data: $data");
          
          List<dynamic> postinganList = [];
          
          // Handle berbagai kemungkinan struktur response
          if (data is List) {
            print("📋 Response is direct List");
            postinganList = data;
          } else if (data['data'] is List) {
            print("📋 Response has 'data' key with List");
            postinganList = data['data'];
          } else if (data['items'] is List) {
            print("📋 Response has 'items' key with List");
            postinganList = data['items'];
          } else if (data['postingan'] is List) {
            print("📋 Response has 'postingan' key with List");
            postinganList = data['postingan'];
          } else if (data['posts'] is List) {
            print("📋 Response has 'posts' key with List");
            postinganList = data['posts'];
          } else {
            print("⚠️ Unknown response structure, trying to extract any list");
            // Coba cari key yang mengandung list
            data.forEach((key, value) {
              if (value is List) {
                print("📋 Found list in key: $key");
                postinganList = value;
              }
            });
          }

          print("📊 Page $page: Found ${postinganList.length} postingan items");

          if (postinganList.isEmpty) {
            hasMoreData = false;
            print("✅ No more data at page $page - stopping pagination");
          } else {
            print("🔄 Processing ${postinganList.length} postingan items");
            final List<Postingan> pagePostingan = postinganList
                .map((json) {
                  print("🔧 Mapping JSON to Postingan: $json");
                  return Postingan.fromJson(json);
                })
                .toList();
            allPostingan.addAll(pagePostingan);
            print("📈 Total postingan so far: ${allPostingan.length}");
            
            // Cek apakah masih ada halaman berikutnya
            final meta = data['meta'] ?? data['pagination'] ?? data['page_info'];
            if (meta != null) {
              print("📑 Pagination metadata found: $meta");
              final int? currentPage = meta['current_page'] ?? meta['page'];
              final int? lastPage = meta['last_page'] ?? meta['total_pages'];
              final bool? hasNext = meta['has_next'] ?? meta['next_page'];
              
              if (currentPage != null && lastPage != null && currentPage >= lastPage) {
                hasMoreData = false;
                print("✅ Reached last page: $currentPage/$lastPage");
              } else if (hasNext != null && !hasNext) {
                hasMoreData = false;
                print("✅ No next page available");
              } else {
                page++;
                print("➡️ Moving to next page: $page");
              }
            } else {
              // Jika tidak ada metadata, asumsikan single page
              hasMoreData = false;
              print("✅ No pagination metadata - assuming single page");
            }
          }
        } else {
          print("❌ API Error - Status: ${response['statusCode']}, Data: ${response['data']}");
          hasMoreData = false;
          
          // Jika 404 atau error lain, return empty list
          if (response['statusCode'] == 404) {
            print("⚠️ Endpoint not found (404) - returning empty list");
            return [];
          }
          
          throw Exception('Failed to load postingan: ${response['data']['message'] ?? 'Unknown error'}');
        }
      }

      print("🎉 FINISHED getPostinganByJadwal - Total: ${allPostingan.length} postingan for jadwalId: $jadwalId");
      return allPostingan;
    } catch (e) {
      print("💥 ERROR in getPostinganByJadwal: $e");
      print("🔄 Returning empty list due to error");
      return [];
    }
  }

  // Create new postingan - DISESUAIKAN
  static Future<Map<String, dynamic>> createPostingan({
    required int jadwalId,
    required String judul,
    required String konten,
    int? dosenId,
    String? fileUrl,
  }) async {
    print("🚀 START createPostingan - jadwalId: $jadwalId, judul: $judul");
    _validateRequiredParams(jadwalId: jadwalId);

    try {
      // Jika dosenId tidak diberikan, ambil dari user data
      print("🔍 Getting dosenId...");
      int finalDosenId = dosenId ?? await _getCurrentDosenId();
      print("✅ Using dosenId: $finalDosenId");

      final body = {
        'jadwal_id': jadwalId.toString(),
        'dosen_id': finalDosenId.toString(),
        'judul': judul,
        'konten': konten,
        if (fileUrl != null && fileUrl.isNotEmpty) 'file_url': fileUrl,
      };

      print("📤 Creating postingan with body: $body");

      final response = await ApiService.postRequest(endpoint, body);
      print("📡 Create postingan response - Status: ${response['statusCode']}, Data: ${response['data']}");

      if (response['statusCode'] == 201 || response['statusCode'] == 200) {
        print("✅ Postingan created successfully");
        final responseData = response['data']['data'] ?? response['data'];
        print("🔧 Response data for parsing: $responseData");
        
        return {
          'success': true,
          'data': Postingan.fromJson(responseData),
          'message': 'Postingan berhasil dibuat'
        };
      } else {
        print("❌ Failed to create postingan: ${response['data']}");
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Gagal membuat postingan'
        };
      }
    } catch (e) {
      print("💥 ERROR in createPostingan: $e");
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // Helper method untuk mendapatkan dosenId dari user yang login
  static Future<int> _getCurrentDosenId() async {
    print("🔍 START _getCurrentDosenId");
    try {
      print("🔍 Getting user data from AuthService...");
      final userData = await AuthService.getUserData();
      print("🔍 User data: $userData");
      
      if (userData['dosen'] != null && userData['dosen']['id'] != null) {
        final dosenId = userData['dosen']['id'];
        print("✅ Found dosenId in user data: $dosenId");
        return dosenId;
      }
      
      print("🔍 Getting dosen data from AuthService...");
      final dosenData = await AuthService.getDosen();
      print("🔍 Dosen data: $dosenData");
      
      if (dosenData['id'] != null) {
        final dosenId = dosenData['id'];
        print("✅ Found dosenId in dosen data: $dosenId");
        return dosenId;
      }
      
      print("❌ No dosenId found in user data or dosen data");
      throw Exception('Dosen ID tidak ditemukan');
    } catch (e) {
      print("💥 ERROR in _getCurrentDosenId: $e");
      throw Exception('Tidak dapat mendapatkan ID dosen: $e');
    }
  }

  // Create postingan dengan file upload (image/document) - DISESUAIKAN
  static Future<Map<String, dynamic>> createPostinganWithFile({
    required int jadwalId,
    required String judul,
    required String konten,
    required List<int> fileBytes,
    required String fileName,
    int? dosenId,
  }) async {
    print("🚀 START createPostinganWithFile - jadwalId: $jadwalId, fileName: $fileName");
    _validateRequiredParams(jadwalId: jadwalId);

    try {
      print("🔍 Getting auth token...");
      final token = await AuthService.getToken();
      final url = Uri.parse('${ApiService.baseUrl}/$endpoint/upload');
      print("🌐 Upload URL: $url");

      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      print("🔑 Token set in headers");

      // Jika dosenId tidak diberikan, ambil dari user data
      print("🔍 Getting dosenId...");
      int finalDosenId = dosenId ?? await _getCurrentDosenId();
      print("✅ Using dosenId: $finalDosenId");

      // Fields - sesuaikan dengan field yang diharapkan API
      request.fields['jadwal_id'] = jadwalId.toString();
      request.fields['dosen_id'] = finalDosenId.toString();
      request.fields['judul'] = judul;
      request.fields['konten'] = konten;

      print("📋 Request fields: ${request.fields}");

      // File - sesuaikan dengan field file API
      print("📎 Adding file to request: $fileName (${fileBytes.length} bytes)");
      request.files.add(http.MultipartFile.fromBytes(
        'file', // atau 'image' tergantung API
        fileBytes, 
        filename: fileName
      ));

      print("📤 Sending multipart request...");
      final streamedResponse = await request.send();
      print("📡 Got streamed response");
      
      final response = await http.Response.fromStream(streamedResponse);
      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("✅ Postingan with file uploaded successfully");
        print("🔧 Response data: $responseData");
        
        return {
          'success': true,
          'data': Postingan.fromJson(responseData['data'] ?? responseData),
          'message': 'Postingan berhasil diupload'
        };
      } else {
        print("❌ Failed to upload postingan: ${response.body}");
        return {
          'success': false,
          'message': 'Gagal upload postingan: ${response.body}'
        };
      }
    } catch (e) {
      print("💥 ERROR in createPostinganWithFile: $e");
      return {
        'success': false,
        'message': 'Error uploading: $e'
      };
    }
  }

  // Delete postingan by ID - DISESUAIKAN
  static Future<Map<String, dynamic>> deletePostingan({required int postinganId}) async {
    print("🚀 START deletePostingan - postinganId: $postinganId");
    try {
      final endpointUrl = '$endpoint/$postinganId';
      print("🌐 API Call - DELETE $endpointUrl");
      
      final response = await ApiService.deleteRequest(endpointUrl);
      print("📡 Delete response - Status: ${response['statusCode']}, Data: ${response['data']}");

      if (response['statusCode'] == 200 || response['statusCode'] == 204) {
        print("✅ Postingan deleted successfully");
        return {
          'success': true,
          'message': 'Postingan berhasil dihapus'
        };
      } else {
        print("❌ Failed to delete postingan: ${response['data']}");
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Gagal menghapus postingan'
        };
      }
    } catch (e) {
      print("💥 ERROR in deletePostingan: $e");
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // Update postingan - DISESUAIKAN
  static Future<Map<String, dynamic>> updatePostingan({
    required int postinganId,
    required String judul,
    required String konten,
    String? fileUrl,
  }) async {
    print("🚀 START updatePostingan - postinganId: $postinganId, judul: $judul");
    try {
      final body = {
        'judul': judul,
        'konten': konten,
        if (fileUrl != null && fileUrl.isNotEmpty) 'file_url': fileUrl,
      };

      print("📤 Updating postingan $postinganId with body: $body");

      final endpointUrl = '$endpoint/$postinganId';
      final response = await ApiService.putRequest(endpointUrl, body);
      
      print("📡 Update response - Status: ${response['statusCode']}, Data: ${response['data']}");

      if (response['statusCode'] == 200) {
        print("✅ Postingan updated successfully");
        final responseData = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'data': Postingan.fromJson(responseData),
          'message': 'Postingan berhasil diupdate'
        };
      } else {
        print("❌ Failed to update postingan: ${response['data']}");
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Gagal mengupdate postingan'
        };
      }
    } catch (e) {
      print("💥 ERROR in updatePostingan: $e");
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // Get postingan by ID - DISESUAIKAN
  static Future<Map<String, dynamic>> getPostinganById({required int postinganId}) async {
    print("🚀 START getPostinganById - postinganId: $postinganId");
    try {
      final endpointUrl = '$endpoint/$postinganId';
      print("🌐 API Call - GET $endpointUrl");
      
      final response = await ApiService.getRequest(endpointUrl);
      print("📡 Get by ID response - Status: ${response['statusCode']}, Data: ${response['data']}");

      if (response['statusCode'] == 200) {
        print("✅ Postingan retrieved successfully");
        final responseData = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'data': Postingan.fromJson(responseData)
        };
      } else {
        print("❌ Failed to get postingan by ID: ${response['data']}");
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Gagal memuat postingan'
        };
      }
    } catch (e) {
      print("💥 ERROR in getPostinganById: $e");
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // Get semua postingan (tanpa filter) - untuk admin/dosen
  static Future<List<Postingan>> getAllPostingan() async {
    print("🚀 START getAllPostingan");
    try {
      print("🌐 API Call - GET $endpoint");
      final response = await ApiService.getRequest(endpoint);
      print("📡 Get all response - Status: ${response['statusCode']}");

      if (response['statusCode'] == 200) {
        final data = response['data'];
        print("📊 Raw response data: $data");
        
        List<dynamic> postinganList = [];
        
        if (data is List) {
          print("📋 Response is direct List");
          postinganList = data;
        } else if (data['data'] is List) {
          print("📋 Response has 'data' key with List");
          postinganList = data['data'];
        }

        print("📊 Total postingan found: ${postinganList.length}");
        final result = postinganList.map((json) {
          print("🔧 Mapping JSON to Postingan: $json");
          return Postingan.fromJson(json);
        }).toList();
        
        print("✅ getAllPostingan completed - Found ${result.length} postingan");
        return result;
      }
      
      print("❌ API returned non-200 status");
      return [];
    } catch (e) {
      print("💥 ERROR in getAllPostingan: $e");
      return [];
    }
  }
}