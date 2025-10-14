import 'api_service.dart';
import 'matkul_service.dart';
import 'auth_service.dart';

class JadwalService {
  // Ambil data jadwal + join nama matkul dengan filter semester & kelas mahasiswa DENGAN PAGINATION
  static Future<List<Map<String, dynamic>>> fetchJadwal() async {
    try {
      // Ambil data mahasiswa dari local storage
      final mahasiswa = await AuthService.getMahasiswa();
      final String kelas = mahasiswa['kelas'] ?? '';
      final String prodi = mahasiswa['prodi'] ?? '';

      // Debug print
      print("Data mahasiswa - Kelas: $kelas, Prodi: $prodi");

      // Jika data mahasiswa belum lengkap, return empty
      if (kelas.isEmpty || prodi.isEmpty) {
        print("⚠️ Data kelas atau prodi mahasiswa tidak tersedia");
        return [];
      }

      // Hitung semester berdasarkan tahun masuk
      final int? semester = await _calculateCurrentSemester();
      if (semester == null) {
        print("⚠️ Tidak dapat menghitung semester");
        return [];
      }

      print("🔍 Filter jadwal - Semester: $semester, Kelas: $kelas, Prodi: $prodi");

      // AMBIL DATA JADWAL DENGAN PAGINATION
      final List<dynamic> allJadwalData = await _fetchJadwalWithPagination(
        kelas: kelas,
        prodi: prodi,
        semester: semester.toString(),
      );

      print("✅ Berhasil fetch ${allJadwalData.length} jadwal");

      // DEBUG: Tampilkan data mentah dari API
      print("=== DEBUG: Data mentah dari API ===");
      for (var i = 0; i < allJadwalData.length; i++) {
        final item = allJadwalData[i];
        print("Item $i: $item");
      }
      print("===================================");

      // Ambil data matkul dan dosen untuk join
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();
      final Map<int, String> dosenMap = await _fetchAllDosen();

      // DEBUG: Cek isi matkulMap dan dosenMap
      print("=== DEBUG: Data untuk Join ===");
      print("Total matkul: ${matkulMap.length}");
      print("Total dosen: ${dosenMap.length}");
      print("=============================");

      // Ambil maksimal 5 jadwal dan join matkulId -> nama, dosenId -> nama
      return allJadwalData.take(5).map<Map<String, dynamic>>((item) {
        final int? matkulId = item["matkulId"];
        final int? dosenId = item["dosenId"];

        final matkulName = matkulMap[matkulId] ?? "Mata Kuliah Tidak Diketahui";
        final dosenName = dosenMap[dosenId] ?? "Dosen Tidak Diketahui";

        // Extract id jadwal - coba berbagai kemungkinan field name
        final int? jadwalId =
            item["id"] ?? item["jadwalId"] ?? item["id_jadwal"] ?? int.tryParse(item["id"]?.toString() ?? '');

        return {
          "id": jadwalId, // ID jadwal dari database
          "title": matkulName,
          "dosen": dosenName, // ← Sekarang nama dosen, bukan ID
          "dosenId": dosenId, // ← Simpan juga ID untuk keperluan navigasi
          "kelas": item["kelas"] ?? "Kelas Tidak Diketahui",
          "isRed": false,
          "hari": item["hari"] ?? "",
          "jamMulai": item["jamMulai"] ?? "",
          "jamSelesai": item["jamSelesai"] ?? "",
          "ruangan": item["ruangan"] ?? "",
          "semester": item["semester"]?.toString() ?? "",
          "prodi": item["prodi"] ?? "",
          "matkulId": matkulId, // ID mata kuliah asli
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetch jadwal: $e");
      return [];
    }
  }

  // METHOD BARU: Ambil semua data dosen
  static Future<Map<int, String>> _fetchAllDosen() async {
    try {
      final Map<int, String> allDosenMap = {};
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 10;

      print("🔄 Mulai fetch data dosen...");

      while (hasMoreData && page <= maxPages) {
        final result = await ApiService.getRequest("dosen", queryParams: {'page': page.toString(), 'per_page': '20'});

        print("📄 Dosen - Page $page - Status: ${result['statusCode']}");

        if (result['statusCode'] == 200) {
          final data = result['data'];

          // Handle berbagai struktur response
          List<dynamic> dosenList = [];

          if (data is List) {
            dosenList = data;
          } else if (data['data'] is List) {
            dosenList = data['data'];
          } else if (data['items'] is List) {
            dosenList = data['items'];
          }

          print("📊 Dosen - Page $page: ${dosenList.length} items");

          if (dosenList.isEmpty) {
            hasMoreData = false;
            print("✅ Tidak ada data dosen lagi di page $page");
          } else {
            // Process data dosen
            for (var item in dosenList) {
              try {
                final dynamic id = item["id"];
                final dynamic nama = item["nama"] ?? item["name"];

                if (id != null && nama != null) {
                  final int dosenId = int.tryParse(id.toString()) ?? 0;
                  if (dosenId > 0) {
                    allDosenMap[dosenId] = nama.toString();
                    print("   - Dosen ID $dosenId: $nama");
                  }
                }
              } catch (e) {
                print("⚠️ Error processing dosen item: $e");
              }
            }

            // Cek pagination
            final meta = data['meta'] ?? data['pagination'];
            if (meta != null) {
              final int? currentPage = meta['current_page'] ?? meta['page'];
              final int? lastPage = meta['last_page'] ?? meta['total_pages'];

              if (currentPage != null && lastPage != null && currentPage >= lastPage) {
                hasMoreData = false;
                print("✅ Sudah sampai halaman terakhir dosen: $currentPage/$lastPage");
              } else {
                page++;
              }
            } else {
              page++;
            }
          }
        } else {
          print("❌ Gagal fetch dosen page $page");
          hasMoreData = false;
        }
      }

      print("✅ Total dosen berhasil diambil: ${allDosenMap.length}");
      return allDosenMap;
    } catch (e) {
      print("❌ Error fetch dosen: $e");
      return {};
    }
  }

  // METHOD: Ambil data jadwal dengan pagination
  static Future<List<dynamic>> _fetchJadwalWithPagination({
    required String kelas,
    required String prodi,
    required String semester,
  }) async {
    try {
      final List<dynamic> allJadwalData = [];
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 20;

      print("🔄 Mulai mengambil data jadwal dengan pagination...");

      while (hasMoreData && page <= maxPages) {
        final Map<String, String> queryParams = {
          'kelas': kelas,
          'prodi': prodi,
          'semester': semester,
          'page': page.toString(),
          'per_page': '50',
        };

        final result = await ApiService.getRequest("jadwal", queryParams: queryParams);

        print("📄 Jadwal - Page $page - Status: ${result['statusCode']}");

        if (result['statusCode'] == 200) {
          final data = result['data'];

          // Handle berbagai struktur response API
          List<dynamic> jadwalList = [];

          if (data is List) {
            jadwalList = data;
          } else if (data['data'] is List) {
            jadwalList = data['data'];
          } else if (data['items'] is List) {
            jadwalList = data['items'];
          } else if (data['jadwal'] is List) {
            jadwalList = data['jadwal'];
          }

          print("📊 Jadwal - Page $page: ${jadwalList.length} jadwal");

          if (jadwalList.isEmpty) {
            hasMoreData = false;
            print("✅ Tidak ada data lagi di page $page");
          } else {
            allJadwalData.addAll(jadwalList);

            // Cek apakah masih ada halaman berikutnya
            final meta = data['meta'] ?? data['pagination'] ?? data['page_info'];
            if (meta != null) {
              final int? currentPage = meta['current_page'] ?? meta['page'];
              final int? lastPage = meta['last_page'] ?? meta['total_pages'];
              final bool? hasNext = meta['has_next'] ?? meta['next_page'];

              if (currentPage != null && lastPage != null && currentPage >= lastPage) {
                hasMoreData = false;
                print("✅ Sudah sampai di halaman terakhir: $currentPage/$lastPage");
              } else if (hasNext != null && !hasNext) {
                hasMoreData = false;
                print("✅ Tidak ada halaman berikutnya");
              } else {
                page++;
              }
            } else {
              if (jadwalList.length < 50) {
                hasMoreData = false;
                print("✅ Kemungkinan last page (data < per_page)");
              } else {
                page++;
              }
            }
          }
        } else {
          print("❌ Gagal fetch jadwal page $page: ${result['data']}");
          hasMoreData = false;
        }
      }

      print("✅ Total jadwal berhasil diambil: ${allJadwalData.length}");
      return allJadwalData;
    } catch (e) {
      print("❌ Error dalam pagination jadwal: $e");
      return [];
    }
  }

  // Method untuk menghitung semester berdasarkan tahun masuk
  static Future<int?> _calculateCurrentSemester() async {
    try {
      final mahasiswa = await AuthService.getMahasiswa();
      final String tahunMasukStr = mahasiswa['tahunMasuk'] ?? '';

      if (tahunMasukStr.isEmpty) {
        print("⚠️ Tahun masuk tidak tersedia");
        return null;
      }

      final int? tahunMasuk = int.tryParse(tahunMasukStr);
      if (tahunMasuk == null) {
        print("⚠️ Format tahun masuk tidak valid: $tahunMasukStr");
        return null;
      }

      final DateTime now = DateTime.now();
      final int currentYear = now.year;
      final int currentMonth = now.month;

      // Hitung selisih tahun
      int tahunAkademik = currentYear;
      int semester;

      if (currentMonth >= 2 && currentMonth <= 7) {
        // Semester Genap: Februari - Juli
        semester = (currentYear - tahunMasuk) * 2;
      } else {
        // Semester Ganjil: Agustus - Januari
        semester = ((currentYear - tahunMasuk) * 2) + 1;
      }

      // Jika bulan Januari, masih termasuk semester ganjil tahun sebelumnya
      if (currentMonth == 1) {
        semester = ((currentYear - 1 - tahunMasuk) * 2) + 1;
      }

      // Pastikan semester tidak kurang dari 1
      final int finalSemester = semester < 1 ? 1 : semester;
      print("📅 Kalkulasi semester: Tahun Masuk $tahunMasuk -> Semester $finalSemester");

      return finalSemester;
    } catch (e) {
      print("❌ Error menghitung semester: $e");
      return null;
    }
  }

  // Method alternatif jika ingin mengambil semua jadwal tanpa limit
  static Future<List<Map<String, dynamic>>> fetchAllJadwal() async {
    try {
      final mahasiswa = await AuthService.getMahasiswa();
      final String kelas = mahasiswa['kelas'] ?? '';
      final String prodi = mahasiswa['prodi'] ?? '';

      if (kelas.isEmpty || prodi.isEmpty) {
        return [];
      }

      final int? semester = await _calculateCurrentSemester();
      if (semester == null) {
        return [];
      }

      // Gunakan method pagination yang baru
      final List<dynamic> allJadwalData = await _fetchJadwalWithPagination(
        kelas: kelas,
        prodi: prodi,
        semester: semester.toString(),
      );

      // Ambil data matkul dan dosen untuk join
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();
      final Map<int, String> dosenMap = await _fetchAllDosen();

      return allJadwalData.map<Map<String, dynamic>>((item) {
        final int? matkulId = item["matkulId"];
        final int? dosenId = item["dosenId"];

        final matkulName = matkulMap[matkulId] ?? "Mata Kuliah Tidak Diketahui";
        final dosenName = dosenMap[dosenId] ?? "Dosen Tidak Diketahui";

        // Extract id jadwal - coba berbagai kemungkinan field name
        final int? jadwalId =
            item["id"] ?? item["jadwalId"] ?? item["id_jadwal"] ?? int.tryParse(item["id"]?.toString() ?? '');

        return {
          "id": jadwalId, // ID jadwal dari database
          "title": matkulName,
          "dosen": dosenName, // ← Sekarang nama dosen, bukan ID
          "dosenId": dosenId, // ← Simpan juga ID untuk keperluan navigasi
          "kelas": item["kelas"] ?? "Kelas Tidak Diketahui",
          "isRed": false,
          "hari": item["hari"] ?? "",
          "jamMulai": item["jamMulai"] ?? "",
          "jamSelesai": item["jamSelesai"] ?? "",
          "ruangan": item["ruangan"] ?? "",
          "semester": item["semester"]?.toString() ?? "",
          "prodi": item["prodi"] ?? "",
          "matkulId": matkulId, // ID mata kuliah asli
        };
      }).toList();
    } catch (e) {
      print("Error fetch all jadwal: $e");
      return [];
    }
  }
}
