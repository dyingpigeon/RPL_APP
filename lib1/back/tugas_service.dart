import 'api_service.dart';
import 'auth_service.dart';

class TugasService {
  // Ambil data tugas dengan filter berdasarkan mahasiswa
  static Future<List<Map<String, dynamic>>> fetchTugas() async {
    try {
      // Ambil data mahasiswa dari local storage
      final mahasiswa = await AuthService.getMahasiswa();
      final String kelas = mahasiswa['kelas'] ?? '';
      final String prodi = mahasiswa['prodi'] ?? '';

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

      print("🔍 Filter tugas - Semester: $semester, Kelas: $kelas, Prodi: $prodi");

      // Query parameters untuk filter
      final Map<String, String> queryParams = {'kelas': kelas, 'prodi': prodi, 'semester': semester.toString()};

      final result = await ApiService.getRequest("tugas", queryParams: queryParams);

      if (result['statusCode'] != 200) {
        print("❌ Gagal fetch tugas: ${result['data']}");
        return [];
      }

      final List<dynamic> tugasData = result['data']['data'];
      print("✅ Berhasil fetch ${tugasData.length} tugas");

      // Ambil maksimal 5 tugas dan urutkan berdasarkan deadline
      final sortedTugas = List.from(tugasData)..sort((a, b) {
        final deadlineA = a['deadline']?.toString() ?? '';
        final deadlineB = b['deadline']?.toString() ?? '';
        return deadlineA.compareTo(deadlineB);
      });

      return sortedTugas.take(5).map<Map<String, dynamic>>((item) {
        return {
          "id": item["id"],
          "judul": item["judul"] ?? "Tugas Tanpa Judul",
          "deskripsi": item["deskripsi"] ?? "",
          "dosen": item["dosenId"]?.toString() ?? "Dosen Tidak Diketahui",
          "deadline": item["deadline"] ?? "",
          "jadwalId": item["jadwalId"],
          "fileUrl": item["fileUrl"] ?? "",
          "isRed": _isDeadlineClose(item["deadline"]), // tambah warning untuk deadline dekat
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetch tugas: $e");
      return [];
    }
  }

  // Method untuk menghitung semester
  static Future<int?> _calculateCurrentSemester() async {
    try {
      final mahasiswa = await AuthService.getMahasiswa();
      final String tahunMasukStr = mahasiswa['tahunMasuk'] ?? '';

      if (tahunMasukStr.isEmpty) return null;

      final int? tahunMasuk = int.tryParse(tahunMasukStr);
      if (tahunMasuk == null) return null;

      final DateTime now = DateTime.now();
      final int currentYear = now.year;
      final int currentMonth = now.month;

      int semester;
      if (currentMonth >= 2 && currentMonth <= 7) {
        semester = (currentYear - tahunMasuk) * 2;
      } else {
        semester = ((currentYear - tahunMasuk) * 2) + 1;
      }

      if (currentMonth == 1) {
        semester = ((currentYear - 1 - tahunMasuk) * 2) + 1;
      }

      return semester < 1 ? 1 : semester;
    } catch (e) {
      print("Error menghitung semester: $e");
      return null;
    }
  }

  // Cek jika deadline kurang dari 3 hari
  static bool _isDeadlineClose(String? deadline) {
    if (deadline == null) return false;

    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      return difference <= 3 && difference >= 0;
    } catch (e) {
      return false;
    }
  }
}
