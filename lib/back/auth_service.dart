import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ----------------------------
  // LOGIN
  // ----------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiService.postRequest("login", {"email": email, "password": password});

    if (result['statusCode'] == 200) {
      try {
        final outerData = result['data'];
        final responseData = outerData['data'];

        final userData = responseData['user'];
        final token = responseData['token'];
        final mahasiswa = responseData['mahasiswa'];

        final prefs = await SharedPreferences.getInstance();

        // Simpan data user
        await prefs.setInt('user_id', userData['id']);
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userRole', userData['role']);
        await prefs.setBool('userEmailVerified', userData['email_verified']);
        await prefs.setString('token', token);

        // Simpan data mahasiswa
        if (mahasiswa != null) {
          await prefs.setInt('mahasiswa_id', mahasiswa['id']);
          await prefs.setInt('mahasiswa_user', mahasiswa['userId'] ?? '');
          await prefs.setString('mahasiswa_nim', mahasiswa['nim'] ?? '');
          await prefs.setString('mahasiswa_kelas', mahasiswa['kelas'] ?? '');
          await prefs.setString('mahasiswa_prodi', mahasiswa['prodi'] ?? '');
          await prefs.setString('mahasiswa_diploma', mahasiswa['diploma'] ?? '');
          await prefs.setString('mahasiswa_tahun_masuk', mahasiswa['tahunMasuk'] ?? '');
          await prefs.setInt('mahasiswa_nomor_prodi', mahasiswa['nomorProdi'] ?? 0);
        }
      } catch (e) {
        print("❌ ERROR menyimpan data user: $e");
      }
    }

    return result;
  }

  // ----------------------------
  // SIGN UP
  // ----------------------------
  static Future<Map<String, dynamic>> signUp(String name, String email, String password, String role) async {
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
    final result = await ApiService.postRequest("forgot-password", {"email": email});
    return result;
  }

  // ----------------------------
  // RESET PASSWORD
  // ----------------------------
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token, // OTP token dari email
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await ApiService.postRequest("reset-password", {
      "email": email,
      "token": token,
      "password": password,
      "password_confirmation": passwordConfirmation,
    });
    return result;
  }

  // ----------------------------
  // UPDATE MAHASISWA
  // ----------------------------
  static Future<Map<String, dynamic>> updateMahasiswa({
    required int id,
    required int idu,
    required String nama,
    required String nim,
    required String kelas,
    required String prodi,
  }) async {
    final token = await getToken();

    final result = await ApiService.putRequest("mahasiswa/$id", {
      // "nama": nama,
      "nim": nim,
      "kelas": kelas,
      "prodi": prodi,
    }, token: token);

    // final resultuser = await ApiService.putRequest("user/$idu", {
    //   "name": nama,
    //   // "nim": nim,
    //   // "kelas": kelas,
    //   // "prodi": prodi,
    // }, token: token);

    if (result['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // Debug response structure
        print("📦 Struktur response:");
        print("   - result: ${result.keys}");
        print("   - result['data']: ${result['data']}");

        // Handle berbagai kemungkinan struktur response
        dynamic responseData;

        if (result['data'] is Map && result['data'].containsKey('data')) {
          responseData = result['data']['data']; // Format: {"data": {...}}
        } else if (result['data'] is Map) {
          responseData = result['data']; // Format: langsung object
        } else {
          responseData = result['data']; // Fallback
        }

        print("🔍 Data dari response API:");
        print("   - responseData: $responseData");

        if (responseData is Map) {
          // Gunakan data dari API, fallback ke parameter jika tidak ada
          await prefs.setString('mahasiswa_nim', (responseData['nim']?.toString() ?? nim));
          await prefs.setString('mahasiswa_prodi', (responseData['prodi']?.toString() ?? prodi));
          await prefs.setString('mahasiswa_kelas', (responseData['kelas']?.toString() ?? kelas));
          await prefs.setString('mahasiswa_tahun_masuk', (responseData['tahunMasuk']?.toString() ?? kelas));

          // Data tambahan dari response
          if (responseData['id'] != null) {
            await prefs.setInt('mahasiswa_id', responseData['id'] as int);
          }
          if (responseData['userId'] != null) {
            await prefs.setInt('user_id', responseData['userId'] as int);
          }
          if (responseData['tahunMasuk'] != null) {
            await prefs.setString('tahunMasuk', responseData['tahunMasuk'].toString());
          }
          if (responseData['tahunMasuk'] != null) {
            await prefs.setString('tahunMasuk', responseData['tahunMasuk'].toString());
          }

          print("✅ Berhasil update SharedPreferences dari API response");
        } else {
          // Fallback ke parameter jika struktur tidak sesuai
          print("⚠️ Struktur response tidak sesuai, menggunakan parameter sebagai fallback");
          await prefs.setString('mahasiswa_nim', nim);
          await prefs.setString('mahasiswa_prodi', prodi);
          await prefs.setString('mahasiswa_kelas', kelas);
        }
      } catch (e) {
        print("❌ Error update local mahasiswa: $e");

        // Fallback: simpan menggunakan parameter
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('mahasiswa_nim', nim);
          await prefs.setString('mahasiswa_prodi', prodi);
          await prefs.setString('mahasiswa_kelas', kelas);
          print("✅ Fallback: SharedPreferences diupdate menggunakan parameter");
        } catch (fallbackError) {
          print("❌ Fallback juga gagal: $fallbackError");
        }
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> updateUser({required int idu, required String nama}) async {
    final token = await getToken();

    final resultuser = await ApiService.putRequest("user/$idu", {
      "name": nama,
      // "nim": nim,
      // "kelas": kelas,
      // "prodi": prodi,
    }, token: token);

    if (resultuser['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mahasiswa_nama', nama);
        await prefs.setString('userName', nama);
        // await prefs.setString('mahasiswa_nim', nim);
        // await prefs.setString('mahasiswa_prodi', prodi);
        // await prefs.setString('mahasiswa_kelas', kelas);
      } catch (e) {
        print("Error update local mahasiswa: $e");
      }
    }

    return resultuser;
  }

  // ----------------------------
  // GET DATA LOCAL
  // ----------------------------
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<bool> isEmailVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('userEmailVerified') ?? false;
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt('user_id'),
      "name": prefs.getString('userName') ?? '',
      "email": prefs.getString('userEmail') ?? '',
      "role": prefs.getString('userRole') ?? '',
      "email_verified": prefs.getBool('userEmailVerified') ?? false,
    };
  }

  static Future<Map<String, dynamic>> getMahasiswa() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt('mahasiswa_id'),
      "nama": prefs.getString('mahasiswa_nama') ?? '',
      "nim": prefs.getString('mahasiswa_nim') ?? '',
      "kelas": prefs.getString('mahasiswa_kelas') ?? '',
      "prodi": prefs.getString('mahasiswa_prodi') ?? '',
      "diploma": prefs.getString('mahasiswa_diploma') ?? '',
      "tahunMasuk": prefs.getString('mahasiswa_tahun_masuk') ?? '',
      "nomorProdi": prefs.getInt('mahasiswa_nomor_prodi') ?? 0,
    };
  }

  // ----------------------------
  // UTILITY METHODS
  // ----------------------------
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isMahasiswa() async {
    final role = await getUserRole();
    return role == 'mahasiswa';
  }

  static Future<bool> hasMahasiswaData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('mahasiswa_id') != null;
  }

  // ----------------------------
  // LOGOUT
  // ----------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ----------------------------
  // UTILITY METHODS
  // // ----------------------------
  // static Future<bool> isLoggedIn() async {
  //   final token = await getToken();
  //   return token != null && token.isNotEmpty;
  // }

  // static Future<bool> isMahasiswa() async {
  //   final role = await getUserRole();
  //   return role == 'mahasiswa';
  // }

  // static Future<bool> hasMahasiswaData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getInt('mahasiswa_id') != null;
  // }

  // // ----------------------------
  // // LOGOUT
  // // ----------------------------
  // static Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  // }
}
