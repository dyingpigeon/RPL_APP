import 'api_service.dart';

class MatkulService {
  static Future<Map<int, String>> fetchMatkul() async {
    try {
      final Map<int, String> allMatkulMap = {};
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 10;

      print("🔄 Mulai fetch mata kuliah dengan pagination...");

      while (hasMoreData && page <= maxPages) {
        try {
          final result = await ApiService.getRequest(
            "mata-kuliah",
            queryParams: {
              'page': page.toString(),
              'per_page': '20', // Kurangi per_page untuk menghindari response terlalu besar
            },
          );

          print("📄 Mata kuliah - Page $page - Status: ${result['statusCode']}");

          if (result['statusCode'] == 200) {
            final data = result['data'];

            // Handle berbagai struktur response
            List<dynamic> matkulList = [];

            if (data is List) {
              matkulList = data;
            } else if (data['data'] is List) {
              matkulList = data['data'];
            } else if (data['items'] is List) {
              matkulList = data['items'];
            }

            print("📊 Mata kuliah - Page $page: ${matkulList.length} items");

            if (matkulList.isEmpty) {
              hasMoreData = false;
              print("✅ Tidak ada data mata kuliah lagi di page $page");
            } else {
              // Process data
              for (var item in matkulList) {
                try {
                  final dynamic id = item["id"];
                  final dynamic namaMatkul = item["mataKuliah"] ?? item["nama"] ?? item["name"];

                  if (id != null && namaMatkul != null) {
                    final int matkulId = int.tryParse(id.toString()) ?? 0;
                    if (matkulId > 0) {
                      allMatkulMap[matkulId] = namaMatkul.toString();
                    }
                  }
                } catch (e) {
                  print("⚠️ Error processing matkul item: $e");
                }
              }

              // Cek pagination metadata
              final meta = data['meta'] ?? data['pagination'];
              if (meta != null) {
                final int? currentPage = meta['current_page'] ?? meta['page'];
                final int? lastPage = meta['last_page'] ?? meta['total_pages'];

                if (currentPage != null && lastPage != null && currentPage >= lastPage) {
                  hasMoreData = false;
                  print("✅ Sudah sampai halaman terakhir mata kuliah: $currentPage/$lastPage");
                } else {
                  page++;
                }
              } else {
                // Jika tidak ada metadata, increment biasa
                page++;
              }
            }
          } else {
            print("❌ Gagal fetch mata kuliah page $page: ${result['data']}");
            hasMoreData = false;
          }
        } catch (e) {
          print("❌ Error fetch mata kuliah page $page: $e");
          // Continue ke page berikutnya meski ada error
          page++;
        }
      }

      print("✅ Total mata kuliah berhasil diambil: ${allMatkulMap.length}");
      return allMatkulMap;
    } catch (e) {
      print("❌ Error fatal fetch mata kuliah: $e");
      return {};
    }
  }
}
