import 'api_service.dart';
import 'matkul_service.dart';

class JadwalService {
  // Ambil data jadwal + join nama matkul
  static Future<List<Map<String, dynamic>>> fetchJadwal() async {
    try {
      // Ambil data jadwal
      final result = await ApiService.getRequest("jadwal");

      if (result['statusCode'] != 200) {
        print("Gagal fetch jadwal: ${result['data']}");
        return [];
      }

      final List<dynamic> jadwalData = result['data']['data'];

      // Ambil data matkul untuk join
      final Map<int, String> matkulMap = await MatkulService.fetchMatkul();

      // Ambil maksimal 5 jadwal dan join matkulId -> nama
      return jadwalData.take(5).map<Map<String, dynamic>>((item) {
        final int matkulId = item["matkulId"];
        final matkulName = matkulMap[matkulId] ?? "Unknown";

        return {
          "title": matkulName, // Nama mata kuliah
          "dosen": item["dosenId"].toString(), // Nanti bisa join API dosen
          "kelas": item["kelas"],
          "isRed": false, // Bisa pakai logika semester/hari
          "hari": item["hari"],
          "jamMulai": item["jamMulai"],
          "jamSelesai": item["jamSelesai"],
          "ruangan": item["ruangan"],
        };
      }).toList();
    } catch (e) {
      print("Error fetch jadwal: $e");
      return [];
    }
  }
}
