import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ----------------------------
  // LOGIN - IMPROVED VERSION
  // ----------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiService.postRequest("login", {"email": email, "password": password});

    if (result['statusCode'] == 200) {
      try {
        final outerData = result['data'];
        final responseData = outerData['data'];
        final userData = responseData['user'];
        final token = responseData['token'];
        
        final prefs = await SharedPreferences.getInstance();

        // Simpan data user (umum untuk semua role)
        await prefs.setInt('user_id', userData['id']);
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userRole', userData['role']);
        await prefs.setBool('userEmailVerified', userData['email_verified'] ?? false);
        await prefs.setString('token', token);

        print("✅ Data user disimpan - Role: ${userData['role']}");

        // Simpan data mahasiswa JIKA ADA
        final mahasiswa = responseData['mahasiswa'];
        if (mahasiswa != null) {
          await _saveMahasiswaData(_convertToStringMap(mahasiswa), prefs);
          print("✅ Data mahasiswa disimpan");
        }

        // Simpan data dosen JIKA ADA
        final dosen = responseData['dosen'];
        if (dosen != null) {
          await _saveDosenData(_convertToStringMap(dosen), prefs);
          print("✅ Data dosen disimpan");
        }

        // Clear data yang tidak sesuai role untuk menghindari konflik
        await _cleanupRoleData(userData['role'], prefs);

      } catch (e) {
        print("❌ ERROR menyimpan data user: $e");
      }
    }

    return result;
  }

  // Helper method to convert any map to Map<String, dynamic>
  static Map<String, dynamic> _convertToStringMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map<dynamic, dynamic>) {
      return data.cast<String, dynamic>();
    } else if (data is Map) {
      // Fallback for any other Map type
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        result[key.toString()] = value;
      });
      return result;
    }
    return {};
  }

  // ----------------------------
  // HELPER METHODS
  // ----------------------------
  static Future<void> _saveMahasiswaData(Map<String, dynamic> mahasiswa, SharedPreferences prefs) async {
    await prefs.setInt('mahasiswa_id', mahasiswa['id'] ?? 0);
    await prefs.setInt('mahasiswa_user', mahasiswa['userId'] ?? 0);
    await prefs.setString('mahasiswa_nim', mahasiswa['nim']?.toString() ?? '');
    await prefs.setString('mahasiswa_kelas', mahasiswa['kelas']?.toString() ?? '');
    await prefs.setString('mahasiswa_prodi', mahasiswa['prodi']?.toString() ?? '');
    await prefs.setString('mahasiswa_diploma', mahasiswa['diploma']?.toString() ?? '');
    await prefs.setString('mahasiswa_tahun_masuk', mahasiswa['tahunMasuk']?.toString() ?? '');
    await prefs.setInt('mahasiswa_nomor_prodi', mahasiswa['nomorProdi'] ?? 0);
  }

  static Future<void> _saveDosenData(Map<String, dynamic> dosen, SharedPreferences prefs) async {
    await prefs.setInt('dosen_id', dosen['id'] ?? 0);
    await prefs.setInt('dosen_user', dosen['userId'] ?? 0);
    await prefs.setString('dosen_nama', dosen['nama']?.toString() ?? '');
    await prefs.setString('dosen_nip', dosen['nip']?.toString() ?? '');
  }

  static Future<void> _cleanupRoleData(String role, SharedPreferences prefs) async {
    if (role == 'mahasiswa') {
      // Hapus data dosen jika user adalah mahasiswa
      await prefs.remove('dosen_id');
      await prefs.remove('dosen_user');
      await prefs.remove('dosen_nama');
      await prefs.remove('dosen_nip');
    } else if (role == 'dosen') {
      // Hapus data mahasiswa jika user adalah dosen
      await prefs.remove('mahasiswa_id');
      await prefs.remove('mahasiswa_user');
      await prefs.remove('mahasiswa_nim');
      await prefs.remove('mahasiswa_kelas');
      await prefs.remove('mahasiswa_prodi');
      await prefs.remove('mahasiswa_diploma');
      await prefs.remove('mahasiswa_tahun_masuk');
      await prefs.remove('mahasiswa_nomor_prodi');
    }
  }

  static dynamic _extractResponseData(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data']; // Format: {"data": {...}}
    } else if (data is Map) {
      return data; // Format: langsung object
    }
    return data; // Fallback
  }

  static Future<void> _fallbackSaveMahasiswa(String nim, String prodi, String kelas) async {
    try {
      final prefs = await SharedPreferences.getInstance(); // FIXED: Added this line
      await prefs.setString('mahasiswa_nim', nim);
      await prefs.setString('mahasiswa_prodi', prodi);
      await prefs.setString('mahasiswa_kelas', kelas);
      print("✅ Fallback: SharedPreferences diupdate menggunakan parameter");
    } catch (fallbackError) {
      print("❌ Fallback juga gagal: $fallbackError");
    }
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
    required String token,
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
  // UPDATE MAHASISWA - IMPROVED
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
      "nim": nim,
      "kelas": kelas,
      "prodi": prodi,
    }, token: token);

    if (result['statusCode'] == 200) {
      final prefs = await SharedPreferences.getInstance(); // MOVED THIS LINE OUTSIDE TRY BLOCK

      try {
        // Debug response structure
        print("📦 Struktur response:");
        print("   - result: ${result.keys}");

        // Handle berbagai kemungkinan struktur response
        dynamic responseData = _extractResponseData(result['data']);

        print("🔍 Data dari response API:");
        print("   - responseData: $responseData");

        if (responseData is Map) {
          // Gunakan data dari API, fallback ke parameter jika tidak ada
          await prefs.setString('mahasiswa_nim', (responseData['nim']?.toString() ?? nim));
          await prefs.setString('mahasiswa_prodi', (responseData['prodi']?.toString() ?? prodi));
          await prefs.setString('mahasiswa_kelas', (responseData['kelas']?.toString() ?? kelas));
          await prefs.setString('mahasiswa_tahun_masuk', (responseData['tahunMasuk']?.toString() ?? ''));

          // Data tambahan dari response dengan type safety
          if (responseData['id'] != null) {
            await prefs.setInt('mahasiswa_id', (responseData['id'] as num).toInt());
          }
          if (responseData['userId'] != null) {
            await prefs.setInt('user_id', (responseData['userId'] as num).toInt());
          }

          // Update user name juga
          await prefs.setString('userName', nama);
          await prefs.setString('mahasiswa_nama', nama);

          print("✅ Berhasil update SharedPreferences dari API response");
        } else {
          // Fallback ke parameter jika struktur tidak sesuai
          print("⚠️ Struktur response tidak sesuai, menggunakan parameter sebagai fallback");
          await _fallbackSaveMahasiswa(nim, prodi, kelas);
          await prefs.setString('userName', nama);
          await prefs.setString('mahasiswa_nama', nama);
        }
      } catch (e) {
        print("❌ Error update local mahasiswa: $e");
        await _fallbackSaveMahasiswa(nim, prodi, kelas);
        await prefs.setString('userName', nama); // NOW prefs IS ACCESSIBLE HERE
      }
    }

    return result;
  }

  // ----------------------------
  // UPDATE USER - IMPROVED
  // ----------------------------
  static Future<Map<String, dynamic>> updateUser({required int idu, required String nama}) async {
    final token = await getToken();

    final resultuser = await ApiService.putRequest("user/$idu", {
      "name": nama,
    }, token: token);

    if (resultuser['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', nama);
        
        // Juga update nama di data mahasiswa jika ada
        if (await isMahasiswa()) {
          await prefs.setString('mahasiswa_nama', nama);
        }
        
        print("✅ User name updated to: $nama");
      } catch (e) {
        print("❌ Error update local user: $e");
      }
    }

    return resultuser;
  }

  // ----------------------------
  // UPDATE DOSEN (NEW METHOD)
  // ----------------------------
  static Future<Map<String, dynamic>> updateDosen({
    required int id,
    required String nama,
    required String nip,
  }) async {
    final token = await getToken();

    final result = await ApiService.putRequest("dosen/$id", {
      "nama": nama,
      "nip": nip,
    }, token: token);

    if (result['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dosen_nama', nama);
        await prefs.setString('dosen_nip', nip);
        await prefs.setString('userName', nama); // Juga update user name
        
        print("✅ Data dosen updated: $nama, NIP: $nip");
      } catch (e) {
        print("❌ Error update local dosen: $e");
      }
    }

    return result;
  }

  // ----------------------------
  // GET DATA LOCAL - IMPROVED
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
    final String? role = prefs.getString('userRole');
    
    Map<String, dynamic> userData = {
      "id": prefs.getInt('user_id'),
      "name": prefs.getString('userName') ?? '',
      "email": prefs.getString('userEmail') ?? '',
      "role": role ?? '',
      "email_verified": prefs.getBool('userEmailVerified') ?? false,
    };

    // Tambahkan data spesifik role
    if (role == 'mahasiswa') {
      final mahasiswa = await getMahasiswa();
      userData.addAll({'mahasiswa': mahasiswa});
    } else if (role == 'dosen') {
      final dosen = await getDosen();
      userData.addAll({'dosen': dosen});
    }

    return userData;
  }

  static Future<Map<String, dynamic>> getMahasiswa() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt('mahasiswa_id') ?? 0,
      "userId": prefs.getInt('mahasiswa_user') ?? 0,
      "nama": prefs.getString('userName') ?? '',
      "nim": prefs.getString('mahasiswa_nim') ?? '',
      "kelas": prefs.getString('mahasiswa_kelas') ?? '',
      "prodi": prefs.getString('mahasiswa_prodi') ?? '',
      "diploma": prefs.getString('mahasiswa_diploma') ?? '',
      "tahunMasuk": prefs.getString('mahasiswa_tahun_masuk') ?? '',
      "nomorProdi": prefs.getInt('mahasiswa_nomor_prodi') ?? 0,
    };
  }

  static Future<Map<String, dynamic>> getDosen() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt('dosen_id') ?? 0,
      "userId": prefs.getInt('dosen_user') ?? 0,
      "nama": prefs.getString('dosen_nama') ?? prefs.getString('userName') ?? '',
      "nip": prefs.getString('dosen_nip') ?? '',
    };
  }

  // ----------------------------
  // UTILITY METHODS - IMPROVED
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

  static Future<bool> isDosen() async {
    final role = await getUserRole();
    return role == 'dosen';
  }

  static Future<bool> hasDosenData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('dosen_id') != null;
  }

  // NEW: Get complete user profile based on role
  static Future<Map<String, dynamic>> getCompleteUserProfile() async {
    final userData = await getUserData();
    final String? role = await getUserRole();
    
    if (role == 'mahasiswa') {
      final mahasiswa = await getMahasiswa();
      return {...userData, ...mahasiswa, 'profile_type': 'mahasiswa'};
    } else if (role == 'dosen') {
      final dosen = await getDosen();
      return {...userData, ...dosen, 'profile_type': 'dosen'};
    }
    
    return {...userData, 'profile_type': 'user'};
  }

  // NEW: Check if user has complete profile
  static Future<bool> hasCompleteProfile() async {
    final String? role = await getUserRole();
    
    if (role == 'mahasiswa') {
      final mahasiswa = await getMahasiswa();
      return mahasiswa['nim']?.isNotEmpty == true && 
             mahasiswa['kelas']?.isNotEmpty == true &&
             mahasiswa['prodi']?.isNotEmpty == true;
    } else if (role == 'dosen') {
      final dosen = await getDosen();
      return dosen['nama']?.isNotEmpty == true;
    }
    
    return true;
  }

  // ----------------------------
  // LOGOUT
  // ----------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("✅ User logged out, all data cleared");
  }
}