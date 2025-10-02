// profile_service.dart
import 'dart:convert';
import 'api_service.dart';

class ProfileService {
  /// Fetch semua data profil mahasiswa
  static Future<List<Map<String, dynamic>>> fetchProfiles() async {
    try {
      // Memanggil API GET endpoint 'mahasiswa'
      final result = await ApiService.getRequest("mahasiswa");

      if (result['data'] != null) {
        // Pastikan data ada
        List<dynamic> data = result['data'];
        // Mengubah List<dynamic> menjadi List<Map<String, dynamic>>
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetchProfiles: $e");
      return [];
    }
  }

  /// Fetch profil mahasiswa berdasarkan ID
  static Future<Map<String, dynamic>?> fetchProfileById(int id) async {
    try {
      final result = await ApiService.getRequest("mahasiswa/$id");
      if (result != null && result['data'] != null) {
        return Map<String, dynamic>.from(result['data']);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetchProfileById: $e");
      return null;
    }
  }
}
