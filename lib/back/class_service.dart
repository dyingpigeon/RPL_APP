import 'api_service.dart'; // ganti sesuai path project kamu

class ClassService {
  // 🔹 Ambil semua jadwal
  static Future<Map<String, dynamic>> getAllJadwal() async {
    return await ApiService.getRequest('jadwal');
  }

  // Mendapatkan daftar kelas dari API
  static Future<Map<String, dynamic>> getClasses({String? token}) async {
    return await ApiService.getRequest('classes', token: token);
  }

  // Mendapatkan detail kelas berdasarkan ID
  static Future<Map<String, dynamic>> getClassById(String id, {String? token}) async {
    return await ApiService.getRequest('classes/$id', token: token);
  }

  // Menambahkan kelas baru
  static Future<Map<String, dynamic>> addClass(Map<String, String> classData, {String? token}) async {
    return await ApiService.postRequest('classes', classData, token: token);
  }

  // Mengupdate data kelas
  static Future<Map<String, dynamic>> updateClass(String id, Map<String, String> classData, {String? token}) async {
    return await ApiService.putRequest('classes/$id', classData, token: token);
  }
}
