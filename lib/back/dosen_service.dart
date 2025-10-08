import 'api_service.dart';

class DosenService {
  // Get nama dosen berdasarkan dosenId
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
