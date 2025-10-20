import 'api_service.dart';
import 'matkul_service.dart';
import 'auth_service.dart';

class JadwalService {
  // METHOD UTAMA: Ambil jadwal berdasarkan role user - DIPERBAIKI
  static Future<List<Map<String, dynamic>>> fetchJadwal() async {
    try {
      final String? role = await AuthService.getUserRole();
      print("🎯 Fetch jadwal untuk role: $role");
      
      if (role == 'mahasiswa') {
        return await _fetchJadwalMahasiswa();
      } else if (role == 'dosen') {
        return await _fetchJadwalDosen();
      } else {
        print("⚠️ Role tidak dikenali: $role");
        return [];
      }
    } catch (e) {
      print("❌ Error fetch jadwal: $e");
      return [];
    }
  }

  // METHOD: Ambil jadwal untuk mahasiswa
  static Future<List<Map<String, dynamic>>> _fetchJadwalMahasiswa() async {
    try {
      // Ambil data mahasiswa dari local storage
      final mahasiswa = await AuthService.getMahasiswa();
      final String kelas = mahasiswa['kelas'] ?? '';
      final String prodi = mahasiswa['prodi'] ?? '';

      // Debug print
      print("👨‍🎓 Data mahasiswa - Kelas: $kelas, Prodi: $prodi");

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

      print("🔍 Filter jadwal mahasiswa - Semester: $semester, Kelas: $kelas, Prodi: $prodi");

      // AMBIL DATA JADWAL DENGAN PAGINATION
      final List<dynamic> allJadwalData = await _fetchJadwalWithPagination(
        kelas: kelas,
        prodi: prodi,
        semester: semester.toString(),
      );

      print("✅ Berhasil fetch ${allJadwalData.length} jadwal untuk mahasiswa");

      return await _processJadwalData(allJadwalData);
    } catch (e) {
      print("❌ Error fetch jadwal mahasiswa: $e");
      return [];
    }
  }

  // METHOD: Ambil jadwal untuk dosen - DIPERBAIKI
  static Future<List<Map<String, dynamic>>> _fetchJadwalDosen() async {
    try {
      // Ambil data dosen dari local storage
      final dosen = await AuthService.getDosen();
      final int dosenId = dosen['id'] ?? 0;

      print("👨‍🏫 Data dosen - ID: $dosenId");

      if (dosenId == 0) {
        print("⚠️ Data dosen ID tidak tersedia");
        return [];
      }

      // Ambil data jadwal dosen dengan filter dosenId
      final List<dynamic> allJadwalData = await _fetchJadwalDosenWithPagination(dosenId: dosenId);

      print("✅ Berhasil fetch ${allJadwalData.length} jadwal untuk dosen ID: $dosenId");

      return await _processJadwalData(allJadwalData);
    } catch (e) {
      print("❌ Error fetch jadwal dosen: $e");
      return [];
    }
  }

  // METHOD: Pagination untuk jadwal dosen - DIPERBAIKI
  static Future<List<dynamic>> _fetchJadwalDosenWithPagination({required int dosenId}) async {
    try {
      final List<dynamic> allJadwalData = [];
      int page = 1;
      bool hasMoreData = true;
      int maxPages = 20;

      print("🔄 Mulai mengambil data jadwal dosen dengan dosenId: $dosenId");

      while (hasMoreData && page <= maxPages) {
        final Map<String, String> queryParams = {
          'dosenId': dosenId.toString(), // FILTER BERDASARKAN DOSEN ID
          'page': page.toString(),
          'per_page': '50',
        };

        final result = await ApiService.getRequest("jadwal", queryParams: queryParams);

        print("📄 Jadwal Dosen - Page $page - Status: ${result['statusCode']}");

        if (result['statusCode'] == 200) {
          final data = result['data'];
          List<dynamic> jadwalList = _extractJadwalListFromResponse(data);

          print("📊 Jadwal Dosen - Page $page: ${jadwalList.length} jadwal");

          if (jadwalList.isEmpty) {
            hasMoreData = false;
            print("✅ Tidak ada data jadwal dosen lagi di page $page");
          } else {
            // FILTER LANGSUNG BERDASARKAN DOSEN ID (double check)
            final filteredJadwal = jadwalList.where((item) {
              final itemDosenId = item['dosenId'] ?? 0;
              return itemDosenId == dosenId;
            }).toList();

            allJadwalData.addAll(filteredJadwal);
            
            // Cek pagination
            if (!_hasNextPage(data)) {
              hasMoreData = false;
              print("✅ Sudah sampai di halaman terakhir jadwal dosen");
            } else {
              page++;
            }
          }
        } else {
          print("❌ Gagal fetch jadwal dosen page $page: ${result['data']}");
          hasMoreData = false;
        }
      }

      print("✅ Total jadwal dosen berhasil diambil: ${allJadwalData.length} untuk dosenId: $dosenId");
      return allJadwalData;
    } catch (e) {
      print("❌ Error dalam pagination jadwal dosen: $e");
      return [];
    }
  }

  // METHOD BARU: Get jadwal by dosenId (untuk keperluan lain)
  static Future<List<Map<String, dynamic>>> getJadwalByDosenId(int dosenId) async {
    try {
      final List<dynamic> jadwalData = await _fetchJadwalDosenWithPagination(dosenId: dosenId);
      return await _processJadwalData(jadwalData);
    } catch (e) {
      print("❌ Error get jadwal by dosenId: $e");
      return [];
    }
  }

  // METHOD BARU: Get jadwal untuk class detail (dengan validasi dosenId)
  static Future<List<Map<String, dynamic>>> getJadwalForClassDetail(int jadwalId, int dosenId) async {
    try {
      final result = await ApiService.getRequest(
        "jadwal/$jadwalId",
        queryParams: {'dosenId': dosenId.toString()}
      );

      if (result['statusCode'] == 200) {
        final data = _extractJadwalListFromResponse(result['data']);
        if (data.isNotEmpty) {
          final jadwal = data.first;
          // Validasi apakah jadwal ini milik dosen yang bersangkutan
          if (jadwal['dosenId'] == dosenId) {
            return await _processJadwalData([jadwal]);
          } else {
            throw Exception("Jadwal tidak sesuai dengan dosen ID");
          }
        }
      }
      return [];
    } catch (e) {
      print("❌ Error get jadwal for class detail: $e");
      return [];
    }
  }

  // METHOD: Process data jadwal (umum untuk mahasiswa dan dosen)
  static Future<List<Map<String, dynamic>>> _processJadwalData(List<dynamic> jadwalData) async {
    try {
      // Ambil data matkul dan dosen untuk join
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();
      final Map<int, String> dosenMap = await _fetchAllDosen();

      // DEBUG: Cek isi matkulMap dan dosenMap
      print("=== DEBUG: Data untuk Join ===");
      print("Total matkul: ${matkulMap.length}");
      print("Total dosen: ${dosenMap.length}");
      print("Total jadwal: ${jadwalData.length}");
      print("=============================");

      // Ambil maksimal 10 jadwal
      return jadwalData.take(10).map<Map<String, dynamic>>((item) {
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
          "dosen": dosenName,
          "dosenId": dosenId,
          "kelas": item["kelas"] ?? "Kelas Tidak Diketahui",
          "isRed": false,
          "hari": item["hari"] ?? "",
          "jamMulai": item["jamMulai"] ?? "",
          "jamSelesai": item["jamSelesai"] ?? "",
          "ruangan": item["ruangan"] ?? "",
          "semester": item["semester"]?.toString() ?? "",
          "prodi": item["prodi"] ?? "",
          "matkulId": matkulId,
        };
      }).toList();
    } catch (e) {
      print("❌ Error processing jadwal data: $e");
      return [];
    }
  }

  // HELPER: Extract jadwal list dari response
  static List<dynamic> _extractJadwalListFromResponse(dynamic data) {
    if (data is List) {
      return data;
    } else if (data['data'] is List) {
      return data['data'];
    } else if (data['items'] is List) {
      return data['items'];
    } else if (data['jadwal'] is List) {
      return data['jadwal'];
    }
    return [];
  }

  // HELPER: Cek apakah ada halaman berikutnya
  static bool _hasNextPage(dynamic data) {
    final meta = data['meta'] ?? data['pagination'] ?? data['page_info'];
    if (meta != null) {
      final int? currentPage = meta['current_page'] ?? meta['page'];
      final int? lastPage = meta['last_page'] ?? meta['total_pages'];
      final bool? hasNext = meta['has_next'] ?? meta['next_page'];

      if (currentPage != null && lastPage != null && currentPage >= lastPage) {
        return false;
      } else if (hasNext != null && !hasNext) {
        return false;
      }
      return true;
    }
    return false;
  }

  // METHOD: Ambil semua data dosen
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
          List<dynamic> dosenList = _extractJadwalListFromResponse(data);

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
            if (!_hasNextPage(data)) {
              hasMoreData = false;
              print("✅ Sudah sampai halaman terakhir dosen");
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

  // METHOD: Ambil data jadwal dengan pagination (untuk mahasiswa)
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
          List<dynamic> jadwalList = _extractJadwalListFromResponse(data);

          print("📊 Jadwal - Page $page: ${jadwalList.length} jadwal");

          if (jadwalList.isEmpty) {
            hasMoreData = false;
            print("✅ Tidak ada data lagi di page $page");
          } else {
            allJadwalData.addAll(jadwalList);

            // Cek pagination
            if (!_hasNextPage(data)) {
              hasMoreData = false;
              print("✅ Sudah sampai di halaman terakhir");
            } else {
              page++;
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
}