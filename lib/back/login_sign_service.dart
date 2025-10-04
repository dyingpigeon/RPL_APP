import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ----------------------------
  // LOGIN
  // ----------------------------
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final result = await ApiService.postRequest("login", {
      "email": email,
      "password": password,
    });

    if (result['statusCode'] == 200) {
      try {
        final responseData = result['data'];
        final userData = responseData['user'];
        final token = responseData['token'];

        final prefs = await SharedPreferences.getInstance();

        // Simpan data user umum
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userRole', userData['role']);
        await prefs.setString('token', token);

        // Simpan data mahasiswa (kalau ada)
        final mahasiswa = responseData['mahasiswa'];
        if (mahasiswa != null) {
          await prefs.setInt('mahasiswa_id', mahasiswa['id']);
          await prefs.setString('mahasiswa_nama', mahasiswa['nama'] ?? '');
          await prefs.setString('mahasiswa_nim', mahasiswa['nim'] ?? '');
          await prefs.setString('mahasiswa_kelas', mahasiswa['kelas'] ?? '');
          await prefs.setString('mahasiswa_prodi', mahasiswa['prodi'] ?? '');
        }
      } catch (e) {
        print("Error menyimpan data user: $e");
      }
    }

    return result;
  }

  // ----------------------------
  // SIGN UP
  // ----------------------------
  static Future<Map<String, dynamic>> signUp(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final result = await ApiService.postRequest("registrasi", {
      "name": name,
      "email": email,
      "password": password,
      "password_confirmation": password,
      "role": role,
    });
    return result;
  }

  // ----------------------------
  // FORGOT PASSWORD
  // ----------------------------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final result = await ApiService.postRequest("forgotPassword", {
      "email": email,
    });
    return result;
  }

  // ----------------------------
  // RESET PASSWORD
  // ----------------------------
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await ApiService.postRequest("resetPassword", {
      "email": email,
      "otp": otp, // sesuai API
      "newPassword": newPassword, // sesuai API
    });
    return result;
  }

  // ----------------------------
  // UPDATE MAHASISWA
  // ----------------------------
  static Future<Map<String, dynamic>> updateMahasiswa({
    required int id,
    required String nama,
    required String nim,
    required String kelas,
    required String prodi,
  }) async {
    final token = await getToken();

    final result = await ApiService.putRequest("mahasiswa/$id", {
      "nama": nama,
      "nim": nim,
      "kelas": kelas,
    }, token: token);

    if (result['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // update data di lokal juga
        await prefs.setString('mahasiswa_nama', nama);
        await prefs.setString('mahasiswa_nim', nim);
        await prefs.setString('mahasiswa_prodi', prodi);
        await prefs.setString('mahasiswa_kelas', kelas);
      } catch (e) {
        print("Error update local mahasiswa: $e");
      }
    }

    return result;
  }

  // ----------------------------
  // GET DATA LOCAL
  // ----------------------------
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> getMahasiswa() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "id": prefs.getInt('mahasiswa_id'),
      "nama": prefs.getString('mahasiswa_nama') ?? '',
      "nim": prefs.getString('mahasiswa_nim') ?? '',
      "jurusan": prefs.getString('mahasiswa_jurusan') ?? '',
      "prodi": prefs.getString('mahasiswa_prodi') ?? '',
    };
  }

  // ----------------------------
  // LOGOUT
  // ----------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
