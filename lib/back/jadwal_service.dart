import 'api_service.dart';
import 'matkul_service.dart';
import 'auth_service.dart';

class JadwalService {
  // Ambil data jadwal + join nama matkul dengan filter semester & kelas mahasiswa
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
        print("⚠️ Data kelas atau prodi ahasiswa tidak tersedia");
        return [];
      }

      // Hitung semester berdasarkan tahun masuk
      final int? semester = await _calculateCurrentSemester();
      if (semester == null) {
        print("⚠️ Tidak dapat menghitung semester");
        return [];
      }

      print("🔍 Filter jadwal - Semester: $semester, Kelas: $kelas, Prodi: $prodi");

      // Ambil data jadwal dengan filter
      final Map<String, String> queryParams = {'kelas': kelas, 'prodi': prodi, 'semester': semester.toString()};

      final result = await ApiService.getRequest("jadwal", queryParams: queryParams);

      if (result['statusCode'] != 200) {
        print("❌ Gagal fetch jadwal: ${result['data']}");
        return [];
      }

      final List<dynamic> jadwalData = result['data']['data'];
      print("✅ Berhasil fetch ${jadwalData.length} jadwal");

      // DEBUG: Tampilkan data mentah dari API
      print("=== DEBUG: Data mentah dari API ===");
      for (var i = 0; i < jadwalData.length; i++) {
        final item = jadwalData[i];
        print("Item $i: $item");
      }
      print("===================================");

      // Ambil data matkul untuk join
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();

      // Ambil maksimal 5 jadwal dan join matkulId -> nama
      return jadwalData.take(5).map<Map<String, dynamic>>((item) {
        final int? matkulId = item["matkulId"];
        final matkulName = matkulMap[matkulId] ?? "Mata Kuliah Tidak Diketahui";

        // Extract id jadwal - coba berbagai kemungkinan field name
        final int? jadwalId =
            item["id"] ?? item["jadwalId"] ?? item["id_jadwal"] ?? int.tryParse(item["id"]?.toString() ?? '');

        return {
          "id": jadwalId, // ID jadwal dari database
          "title": matkulName,
          "dosen": item["dosenId"] ?? "Dosen Tidak Diketahui",
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

      final Map<String, String> queryParams = {'kelas': kelas, 'prodi': prodi, 'semester': semester.toString()};

      final result = await ApiService.getRequest("jadwal", queryParams: queryParams);

      if (result['statusCode'] != 200) {
        return [];
      }

      final List<dynamic> jadwalData = result['data']['data'];
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();

      return jadwalData.map<Map<String, dynamic>>((item) {
        final int? matkulId = item["matkulId"];
        final matkulName = matkulMap[matkulId] ?? "Mata Kuliah Tidak Diketahui";

        // Extract id jadwal - coba berbagai kemungkinan field name
        final int? jadwalId =
            item["id"] ?? item["jadwalId"] ?? item["id_jadwal"] ?? int.tryParse(item["id"]?.toString() ?? '');

        return {
          "id": jadwalId, // ID jadwal dari database
          "title": matkulName,
          "dosen": item["dosenId"]?.toString() ?? "Dosen Tidak Diketahui",
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
