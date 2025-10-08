import 'api_service.dart';

class MatkulService {
  // Ambil data semua mata kuliah dari API
  static Future<Map<int, String>> fetchMatkul() async {
    try {
      final result = await ApiService.getRequest("mata-kuliah"); // endpoint matkul

      if (result['statusCode'] == 200) {
        final List<dynamic> data = result['data']['data'];

        // Buat map: matkulId -> nama matkul
        final Map<int, String> matkulMap = {};
        for (var item in data) {
          matkulMap[item["id"]] = item["mataKuliah"];
        }

        return matkulMap;
      } else {
        print("Gagal fetch mata kuliah: ${result['data']}");
        return {};
      }
    } catch (e) {
      print("Error fetch mata kuliah: $e");
      return {};
    }
  }
}
