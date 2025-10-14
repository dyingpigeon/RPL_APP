import 'api_service.dart';

class DosenService {
  // Get nama dosen berdasarkan dosenId (tetap sama, tidak butuh pagination)
  static Future<String> getNamaDosen(int dosenId) async {
    try {
      final response = await ApiService.getRequest(
        'dosen/$dosenId', // Endpoint untuk get data dosen
      );

      print('📡 Dosen Response Status: ${response['statusCode']}');
      print('📦 Dosen Response Data: ${response['data']}');

      if (response['statusCode'] == 200) {
        final data = response['data'];

        // Sesuaikan dengan struktur response API Anda
        // Contoh 1: Jika data langsung berisi nama
        if (data['nama'] != null) {
          return data['nama'];
        }

        // Contoh 2: Jika data berada dalam nested object
        if (data['data'] != null && data['data']['nama'] != null) {
          return data['data']['nama'];
        }

        // Contoh 3: Jika menggunakan field 'name' bukan 'nama'
        if (data['name'] != null) {
          return data['name'];
        }

        throw Exception('Field nama tidak ditemukan dalam response');
      } else {
        final errorMessage = response['data']['message'] ?? 'Gagal mengambil data dosen';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 DosenService Error: $e');
      throw Exception('Gagal mengambil data dosen: $e');
    }
  }

  // METHOD BARU: Get semua data dosen dengan handle pagination
  static Future<Map<int, String>> fetchAllDosen() async {
    try {
      final Map<int, String> allDosenMap = {};
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 20; // Safety limit untuk menghindari infinite loop

      print('🔄 Mulai mengambil semua data dosen...');

      while (hasMoreData && page <= maxPages) {
        final response = await ApiService.getRequest(
          'dosen', // Endpoint untuk get semua dosen
          queryParams: {
            'page': page.toString(),
            'per_page': '50', // Sesuaikan dengan maksimal yang diizinkan API
          },
        );

        print('📄 Page $page - Status: ${response['statusCode']}');

        if (response['statusCode'] == 200) {
          final data = response['data'];

          // Handle berbagai struktur response API
          List<dynamic> dosenList = [];

          if (data is List) {
            // Jika response langsung array
            dosenList = data;
          } else if (data['data'] is List) {
            // Jika response ada dalam property 'data'
            dosenList = data['data'];
          } else if (data['items'] is List) {
            // Jika response ada dalam property 'items'
            dosenList = data['items'];
          }

          print('📊 Page $page: ${dosenList.length} dosen');

          if (dosenList.isEmpty) {
            // Tidak ada data lagi, stop loop
            hasMoreData = false;
            print('✅ Tidak ada data lagi di page $page');
          } else {
            // Process data dosen
            for (var dosen in dosenList) {
              final dynamic id = dosen['id'];
              final dynamic nama = dosen['nama'] ?? dosen['name'];

              if (id != null && nama != null) {
                final int dosenId = int.tryParse(id.toString()) ?? 0;
                if (dosenId > 0) {
                  allDosenMap[dosenId] = nama.toString();
                }
              }
            }

            // Cek apakah masih ada halaman berikutnya
            final meta = data['meta'] ?? data['pagination'];
            if (meta != null) {
              final int? currentPage = meta['current_page'] ?? meta['page'];
              final int? lastPage = meta['last_page'] ?? meta['total_pages'];
              final int? total = meta['total'];

              if (currentPage != null && lastPage != null && currentPage >= lastPage) {
                hasMoreData = false;
                print('✅ Sudah sampai di halaman terakhir: $currentPage/$lastPage');
              }
            } else {
              // Jika tidak ada metadata, increment page biasa
              page++;
            }
          }
        } else {
          print('❌ Gagal fetch dosen page $page: ${response['data']}');
          hasMoreData = false;
        }
      }

      print('✅ Total dosen berhasil diambil: ${allDosenMap.length}');
      return allDosenMap;
    } catch (e) {
      print('💥 Error fetch all dosen: $e');
      return {};
    }
  }

  // Alternatif: Get semua data dosen (jika diperlukan)
  static Future<Map<String, dynamic>> getDosenData(int dosenId) async {
    try {
      final response = await ApiService.getRequest('dosen/$dosenId');

      if (response['statusCode'] == 200) {
        return response['data'];
      } else {
        final errorMessage = response['data']['message'] ?? 'Gagal mengambil data dosen';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 DosenService Error: $e');
      throw Exception('Gagal mengambil data dosen: $e');
    }
  }
}
