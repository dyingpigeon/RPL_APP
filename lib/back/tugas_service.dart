import 'api_service.dart';

class TugasService {
  // Ambil daftar tugas dari API
  static Future<List<Map<String, dynamic>>> fetchTugas() async {
    try {
      final result = await ApiService.getRequest("tugas"); // endpoint tugas

      if (result['statusCode'] != 200) {
        print("Gagal fetch tugas: ${result['data']}");
        return [];
      }

      final List<dynamic> data = result['data']['data'];

      // Ambil maksimal 5 tugas
      return data.take(5).map<Map<String, dynamic>>((item) {
        return {
          "id": item["id"],
          "judul": item["judul"],
          "deskripsi": item["deskripsi"],
          "dosen": item["dosenId"].toString(), // nanti bisa join API dosen
          "deadline": item["deadline"],
        };
      }).toList();
    } catch (e) {
      print("Error fetch tugas: $e");
      return [];
    }
  }
}
