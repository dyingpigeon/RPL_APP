// auth_service.dart
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Keys untuk SharedPreferences
  static const String _tokenKey = 'token';
  static const String _tokenExpiresKey = 'token_expires_at';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userRoleKey = 'userRole';
  static const String _userEmailVerifiedKey = 'userEmailVerified';
  static const String _verificationCodeKey = 'verification_code';
  static const String _verificationCodeExpiresKey = 'verification_code_expires';

  // New keys for photo
  static const String _userPhotoKey = 'user_photo';
  static const String _userPhotoUrlKey = 'user_photo_url';

  // Mahasiswa keys
  static const String _mahasiswaIdKey = 'mahasiswa_id';
  static const String _mahasiswaUserIdKey = 'mahasiswa_user';
  static const String _mahasiswaNimKey = 'mahasiswa_nim';
  static const String _mahasiswaKelasKey = 'mahasiswa_kelas';
  static const String _mahasiswaProdiKey = 'mahasiswa_prodi';
  static const String _mahasiswaDiplomaKey = 'mahasiswa_diploma';
  static const String _mahasiswaTahunMasukKey = 'mahasiswa_tahun_masuk';
  static const String _mahasiswaNomorProdiKey = 'mahasiswa_nomor_prodi';
  static const String _mahasiswaNamaKey = 'mahasiswa_nama';

  // Dosen keys
  static const String _dosenIdKey = 'dosen_id';
  static const String _dosenUserIdKey = 'dosen_user';
  static const String _dosenNamaKey = 'dosen_nama';
  static const String _dosenNipKey = 'dosen_nip';

  // ============================
  // AUTHENTICATION METHODS
  // ============================

  // ----------------------------
  // REGISTER (REGISTRASI)
  // ----------------------------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    print('📝 Attempting registration for: $email, role: $role');

    final result = await ApiService.postRequest("registrasi", {
      "name": name,
      "email": email,
      "password": password,
      "password_confirmation": password,
      "role": role,
    });

    if (result['statusCode'] == 201 || result['statusCode'] == 200) {
      print('✅ Registration successful!');
      if (result['data']['success'] == true) {
        // Otomatis login setelah registrasi berhasil
        final loginResult = await login(email, password);
        return loginResult;
      }
    } else {
      print('❌ Registration failed: ${result['data']}');
    }

    return result;
  }

  // ----------------------------
  // LOGIN - UPDATED FOR NEW API RESPONSE
  // ----------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 Attempting login for: $email');

    final result = await ApiService.postRequest("login", {"email": email, "password": password});

    if (result['statusCode'] == 200) {
      try {
        final outerData = result['data'];

        if (outerData['success'] == true) {
          final responseData = outerData['data'];
          final userData = responseData['user'];
          final token = responseData['token'];
          final tokenExpiresAt = responseData['token_expires_at'];

          final prefs = await SharedPreferences.getInstance();

          // Simpan data user (umum untuk semua role) - UPDATED
          await _saveUserData(userData, token, tokenExpiresAt, prefs);
          print("✅ User data saved - Role: ${userData['role']}");

          // Simpan data mahasiswa JIKA ADA - UPDATED
          final mahasiswa = responseData['mahasiswa'];
          if (mahasiswa != null) {
            await _saveMahasiswaData(_convertToStringMap(mahasiswa), prefs);
            print("✅ Mahasiswa data saved");
          }

          // Simpan data dosen JIKA ADA
          final dosen = responseData['dosen'];
          if (dosen != null) {
            await _saveDosenData(_convertToStringMap(dosen), prefs);
            print("✅ Dosen data saved");
          }

          // Clear data yang tidak sesuai role untuk menghindari konflik
          await _cleanupRoleData(userData['role'], prefs);

          print('🎉 Login successful! Token saved, expires at: $tokenExpiresAt');
        } else {
          print('❌ Login failed: ${outerData['message']}');
        }
      } catch (e) {
        print("❌ ERROR saving user data: $e");
        print('🔍 Stack trace: ${e.toString()}');
      }
    } else {
      print('❌ Login failed with status: ${result['statusCode']}');
    }

    return result;
  }

  // ----------------------------
  // LOGOUT
  // ----------------------------
  static Future<Map<String, dynamic>> logout() async {
    print('🚪 Attempting logout...');

    try {
      // Panggil API logout untuk menghapus token di server
      final result = await ApiService.postRequest("logout", {});

      if (result['statusCode'] == 200) {
        print('✅ Logout API call successful');
      } else {
        print('⚠️ Logout API call failed with status: ${result['statusCode']}');
      }
    } catch (e) {
      print('⚠️ Logout API call error: $e');
    } finally {
      // Clear local data regardless of API call result
      final prefs = await SharedPreferences.getInstance();
      await _clearAuthData(prefs);
      print("✅ User logged out, all auth data cleared");
    }

    return {"success": true, "message": "Logout successful"};
  }

  // ----------------------------
  // REFRESH TOKEN
  // ----------------------------
  static Future<Map<String, dynamic>> refreshToken() async {
    print('🔄 Attempting token refresh...');

    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString(_tokenKey);

    // Cek jika sudah ada proses refresh yang berjalan
    if (prefs.getBool('is_refreshing') == true) {
      print('⏳ Token refresh already in progress...');
      return {"success": false, "message": "Refresh already in progress"};
    }

    try {
      await prefs.setBool('is_refreshing', true);

      final response = await ApiService.postRequest("refresh-token", {}).timeout(Duration(seconds: 10));

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data['success'] == true) {
          final newToken = data['data']['token'];
          final newExpiresAt = data['data']['token_expires_at'];

          await prefs.setString(_tokenKey, newToken);
          await prefs.setString(_tokenExpiresKey, newExpiresAt);

          print('🔄 Token refreshed successfully! Expires at: $newExpiresAt');
          return {"success": true, "token": newToken, "expires_at": newExpiresAt};
        }
      }

      print('❌ Token refresh failed: ${response['data']}');
      return {"success": false, "message": "Token refresh failed: ${response['data']['message'] ?? 'Unknown error'}"};
    } catch (e) {
      print('❌ Token refresh error: $e');
      return {"success": false, "message": "Token refresh error: $e"};
    } finally {
      await prefs.setBool('is_refreshing', false);
    }
  }

  // ----------------------------
  // CHECK TOKEN VALIDITY
  // ----------------------------
  static Future<Map<String, dynamic>> checkToken() async {
    print('🔍 Checking token validity...');

    try {
      final response = await ApiService.getRequest('check-token');

      if (response['statusCode'] == 200) {
        print('✅ Token is valid');
        return {"success": true, "valid": true, "user": response['data']['data'] ?? response['data']};
      } else {
        print('❌ Token is invalid: ${response['statusCode']}');
        return {"success": false, "valid": false, "message": "Token validation failed"};
      }
    } catch (e) {
      print('❌ Token check error: $e');
      return {"success": false, "valid": false, "message": "Token check error: $e"};
    }
  }

  // ----------------------------
  // FORGOT PASSWORD
  // ----------------------------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    print('🔑 Requesting password reset for: $email');

    final result = await ApiService.postRequest("forgot-password", {"email": email});

    // ================= DEBUG PRINT LENGKAP =================
    print('-----------------------');
    print('🐛 DEBUG FORGOT PASSWORD RESPONSE:');
    print('📡 Status Code: ${result['statusCode']}');
    print('📦 Response Type: ${result['data'].runtimeType}');
    print('🔍 Full Response Data: ${result['data']}');

    // Cek struktur data
    if (result['data'] is Map) {
      final responseData = result['data'] as Map;
      print('✅ Data is Map - Keys: ${responseData.keys}');
      print('🔑 Success field: ${responseData['success']}');
      print('📝 Message field: ${responseData['message']}');
      print('💾 Data field: ${responseData['data']}');
    } else {
      print('❌ Data is not Map: ${result['data']}');
    }

    // Debug untuk melihat apa yang diakses
    final debugMessage = result['data']?['message'];
    print('🔎 result["data"]?["message"] = $debugMessage');
    print('-----------------------');
    // ================= END DEBUG =================

    if (result['statusCode'] == 200) {
      final responseData = result['data'];

      if (responseData is Map && responseData['success'] == true) {
        print('✅ Password reset successful!');
        return {"success": true, "message": responseData['message'] ?? "Password reset link sent to your email"};
      } else {
        print('❌ API returned success but operation failed');
        final errorMessage = result['data']?['message'] ?? "Gagal mengirim kode verifikasi";
        print('💬 Error message to show: $errorMessage');
        return {"success": false, "message": errorMessage};
      }
    } else {
      print('❌ Password reset request failed');
      final errorMessage = result['data']?['message'] ?? "Gagal mengirim kode verifikasi";
      print('💬 Error message to show: $errorMessage');
      return {"success": false, "message": errorMessage};
    }
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
    print('🔄 Resetting password for: $email');

    final result = await ApiService.postRequest("reset-password", {
      "email": email,
      "token": token,
      "password": password,
      "password_confirmation": passwordConfirmation,
    });

    if (result['statusCode'] == 200) {
      print('✅ Password reset successful!');
      return {"success": true, "message": "Password has been reset successfully"};
    } else {
      print('❌ Password reset failed: ${result['data']}');
      return {"success": false, "message": result['data']['message'] ?? "Password reset failed"};
    }
  }

  // ============================
  // EMAIL VERIFICATION METHODS
  // ============================

  // ----------------------------
  // SEND VERIFICATION CODE
  // ----------------------------
  static Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    print('📧 Sending verification code to: $email');

    final result = await ApiService.postRequest("send-verification", {"email": email});

    print('🔍 Raw API Response: $result');

    if (result['statusCode'] == 200) {
      final responseData = result['data'];

      if (responseData['success'] == true) {
        print('✅ Verification code sent! Message: ${responseData['message']}');

        // Simpan informasi verifikasi lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userEmailKey, email);
        await prefs.setString(_verificationCodeExpiresKey, DateTime.now().add(Duration(minutes: 10)).toIso8601String());

        return {"success": true, "message": responseData['message'] ?? "Verification code sent to your email"};
      } else {
        print('❌ API returned success but operation failed: ${responseData['message']}');
        return {"success": false, "message": responseData['message'] ?? "Failed to send verification code"};
      }
    } else {
      print('❌ Failed to send verification code with status: ${result['statusCode']}');

      final responseData = result['data'];
      String errorMessage = "Failed to send verification code";

      if (responseData is Map) {
        errorMessage = responseData['message'] ?? responseData['error'] ?? "Failed to send verification code";
      }

      return {"success": false, "message": errorMessage};
    }
  }

  // ----------------------------
  // VERIFY CODE
  // ----------------------------
  static Future<Map<String, dynamic>> verifyCode({required String email, required String code}) async {
    print('🔐 Verifying code for: $email');

    final result = await ApiService.postRequest("verify-code", {"email": email, "code": code});

    if (result['statusCode'] == 200) {
      print('✅ Email verified successfully!');

      // Update status verifikasi email di local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userEmailVerifiedKey, true);
      await prefs.remove(_verificationCodeKey);
      await prefs.remove(_verificationCodeExpiresKey);

      return {"success": true, "message": "Email verified successfully"};
    } else {
      print('❌ Email verification failed: ${result['data']}');
      return {"success": false, "message": result['data']['message'] ?? "Email verification failed"};
    }
  }

  // ============================
  // PROFILE UPDATE METHODS
  // ============================

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
    print('📝 Updating mahasiswa data - ID: $id, Nama: $nama');

    final result = await ApiService.putRequest("mahasiswa/$id", {"nim": nim, "kelas": kelas, "prodi": prodi});

    if (result['statusCode'] == 200) {
      final prefs = await SharedPreferences.getInstance();

      try {
        dynamic responseData = _extractResponseData(result['data']);

        if (responseData is Map) {
          await prefs.setString(_mahasiswaNimKey, (responseData['nim']?.toString() ?? nim));
          await prefs.setString(_mahasiswaProdiKey, (responseData['prodi']?.toString() ?? prodi));
          await prefs.setString(_mahasiswaKelasKey, (responseData['kelas']?.toString() ?? kelas));
          await prefs.setString(_mahasiswaTahunMasukKey, (responseData['tahunMasuk']?.toString() ?? ''));
          await prefs.setString(_mahasiswaDiplomaKey, (responseData['diploma']?.toString() ?? ''));

          if (responseData['id'] != null) {
            await prefs.setInt(_mahasiswaIdKey, (responseData['id'] as num).toInt());
          }
          if (responseData['userId'] != null) {
            await prefs.setInt(_userIdKey, (responseData['userId'] as num).toInt());
          }

          await prefs.setString(_userNameKey, nama);
          await prefs.setString(_mahasiswaNamaKey, nama);

          print("✅ Mahasiswa data updated from API response");
        } else {
          await _fallbackSaveMahasiswa(nim, prodi, kelas);
          await prefs.setString(_userNameKey, nama);
          await prefs.setString(_mahasiswaNamaKey, nama);
        }
      } catch (e) {
        print("❌ Error updating local mahasiswa data: $e");
        await _fallbackSaveMahasiswa(nim, prodi, kelas);
        await prefs.setString(_userNameKey, nama);
      }
    }

    return result;
  }

  // ----------------------------
  // UPDATE USER
  // ----------------------------
  static Future<Map<String, dynamic>> updateUser({required int idu, required String nama}) async {
    print('👤 Updating user data - ID: $idu, Nama: $nama');

    final resultuser = await ApiService.putRequest("user/$idu", {"name": nama});

    if (resultuser['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, nama);

        if (await isMahasiswa()) {
          await prefs.setString(_mahasiswaNamaKey, nama);
        }

        print("✅ User name updated to: $nama");
      } catch (e) {
        print("❌ Error updating local user data: $e");
      }
    }

    return resultuser;
  }

  // ----------------------------
  // UPDATE DOSEN
  // ----------------------------
  static Future<Map<String, dynamic>> updateDosen({required int id, required String nama, required String nip}) async {
    print('👨‍🏫 Updating dosen data - ID: $id, Nama: $nama');

    final result = await ApiService.putRequest("dosen/$id", {"nama": nama, "nip": nip});

    if (result['statusCode'] == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_dosenNamaKey, nama);
        await prefs.setString(_dosenNipKey, nip);
        await prefs.setString(_userNameKey, nama);

        print("✅ Dosen data updated: $nama, NIP: $nip");
      } catch (e) {
        print("❌ Error updating local dosen data: $e");
      }
    }

    return result;
  }

  // ============================
  // TOKEN MANAGEMENT METHODS
  // ============================

  // ----------------------------
  // GET TOKEN
  // ----------------------------
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      if (await isTokenExpired()) {
        print('⚠️ Token has expired, attempting refresh...');
        final refreshResult = await refreshToken();
        if (refreshResult['success'] == true) {
          return refreshResult['token'];
        } else {
          await _clearAuthData(prefs);
          return null;
        }
      }
    }

    return token;
  }

  // ----------------------------
  // CHECK TOKEN EXPIRY
  // ----------------------------
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getString(_tokenExpiresKey);

    if (expiresAt == null) return true;

    try {
      final expiryDate = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiryDate.subtract(Duration(minutes: 5))); // 5 minutes buffer

      if (isExpired) {
        print('🔐 Token expires at: $expiresAt, Current time: $now');
      }

      return isExpired;
    } catch (e) {
      print('❌ Error parsing token expiry: $e');
      return true;
    }
  }

  // ----------------------------
  // VALIDATE TOKEN WITH SERVER
  // ----------------------------
  static Future<bool> validateToken() async {
    if (!await isLoggedIn()) {
      return false;
    }

    try {
      final response = await checkToken();
      final isValid = response['success'] == true && response['valid'] == true;

      if (!isValid) {
        print('❌ Token validation failed');
        await logout();
      }

      return isValid;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  // ============================
  // USER DATA GETTERS - UPDATED
  // ============================

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<bool> isEmailVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userEmailVerifiedKey) ?? false;
  }

  // NEW: Get user photo
  static Future<String?> getUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhotoKey);
  }

  // NEW: Get user photo URL
  static Future<String?> getUserPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhotoUrlKey);
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? role = prefs.getString(_userRoleKey);

    Map<String, dynamic> userData = {
      "id": prefs.getInt(_userIdKey),
      "userId": prefs.getInt(_userIdKey), // Tambah field userId untuk consistency
      "name": prefs.getString(_userNameKey) ?? '',
      "email": prefs.getString(_userEmailKey) ?? '',
      "role": role ?? '',
      "email_verified": prefs.getBool(_userEmailVerifiedKey) ?? false,
      "photo": prefs.getString(_userPhotoKey) ?? '',
      "photo_url": prefs.getString(_userPhotoUrlKey) ?? '',
    };

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
      "id": prefs.getInt(_mahasiswaIdKey) ?? 0,
      "userId": prefs.getInt(_mahasiswaUserIdKey) ?? prefs.getInt(_userIdKey) ?? 0,
      "nama": prefs.getString(_mahasiswaNamaKey) ?? prefs.getString(_userNameKey) ?? '',
      "nim": prefs.getString(_mahasiswaNimKey) ?? '',
      "kelas": prefs.getString(_mahasiswaKelasKey) ?? '',
      "prodi": prefs.getString(_mahasiswaProdiKey) ?? '',
      "diploma": prefs.getString(_mahasiswaDiplomaKey) ?? '',
      "tahunMasuk": prefs.getString(_mahasiswaTahunMasukKey) ?? '',
      "nomorProdi": prefs.getInt(_mahasiswaNomorProdiKey) ?? 0,
    };
  }

  static Future<Map<String, dynamic>> getDosen() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getInt(_dosenIdKey) ?? 0,
      "userId": prefs.getInt(_dosenUserIdKey) ?? prefs.getInt(_userIdKey) ?? 0,
      "nama": prefs.getString(_dosenNamaKey) ?? prefs.getString(_userNameKey) ?? '',
      "nip": prefs.getString(_dosenNipKey) ?? '',
    };
  }

  // ============================
  // UTILITY METHODS
  // ============================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final isLoggedIn = token != null && token.isNotEmpty;
    print('🔐 Login status: $isLoggedIn');
    return isLoggedIn;
  }

  static Future<bool> isMahasiswa() async {
    final role = await getUserRole();
    return role == 'mahasiswa';
  }

  static Future<bool> hasMahasiswaData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mahasiswaIdKey) != null;
  }

  static Future<bool> isDosen() async {
    final role = await getUserRole();
    return role == 'dosen';
  }

  static Future<bool> hasDosenData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dosenIdKey) != null;
  }

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

  static Future<bool> hasCompleteProfile() async {
    final String? role = await getUserRole();

    if (role == 'mahasiswa') {
      final mahasiswa = await getMahasiswa();
      return mahasiswa['nim']?.isNotEmpty == true &&
          mahasiswa['kelas']?.isNotEmpty == true &&
          mahasiswa['prodi']?.isNotEmpty == true;
    } else if (role == 'dosen') {
      final dosen = await getDosen();
      return dosen['nama']?.isNotEmpty == true && dosen['nip']?.isNotEmpty == true;
    }

    return true;
  }

  // ============================
  // TEST SERVER CONNECTION
  // ============================
  static Future<Map<String, dynamic>> testServerConnection() async {
    print('🌐 Testing server connection...');

    try {
      final response = await ApiService.getRequest('test-time');

      if (response['statusCode'] == 200) {
        print('✅ Server connection successful');
        return {
          "success": true,
          "server_time": response['data']['server_time'],
          "timezone": response['data']['timezone'],
        };
      } else {
        print('❌ Server connection failed: ${response['statusCode']}');
        return {"success": false, "message": "Server connection failed"};
      }
    } catch (e) {
      print('❌ Server connection error: $e');
      return {"success": false, "message": "Server connection error: $e"};
    }
  }

  // ============================
  // PRIVATE HELPER METHODS - UPDATED
  // ============================

  static Future<void> _saveUserData(
    Map<String, dynamic> userData,
    String token,
    String tokenExpiresAt,
    SharedPreferences prefs,
  ) async {
    // Support both 'userId' and 'id' fields
    await prefs.setInt(_userIdKey, userData['userId'] ?? userData['id'] ?? 0);
    await prefs.setString(_userNameKey, userData['name'] ?? '');
    await prefs.setString(_userEmailKey, userData['email'] ?? '');
    await prefs.setString(_userRoleKey, userData['role'] ?? '');
    await prefs.setBool(_userEmailVerifiedKey, userData['email_verified'] ?? false);

    // Save new photo fields
    await prefs.setString(_userPhotoKey, userData['photo'] ?? '');
    await prefs.setString(_userPhotoUrlKey, userData['photo_url'] ?? '');

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_tokenExpiresKey, tokenExpiresAt);
  }

  static Future<void> _saveMahasiswaData(Map<String, dynamic> mahasiswa, SharedPreferences prefs) async {
    await prefs.setInt(_mahasiswaIdKey, mahasiswa['id'] ?? 0);
    await prefs.setInt(_mahasiswaUserIdKey, mahasiswa['userId'] ?? 0);
    await prefs.setString(_mahasiswaNimKey, mahasiswa['nim']?.toString() ?? '');
    await prefs.setString(_mahasiswaKelasKey, mahasiswa['kelas']?.toString() ?? '');
    await prefs.setString(_mahasiswaProdiKey, mahasiswa['prodi']?.toString() ?? '');
    await prefs.setString(_mahasiswaDiplomaKey, mahasiswa['diploma']?.toString() ?? '');
    await prefs.setString(_mahasiswaTahunMasukKey, mahasiswa['tahunMasuk']?.toString() ?? '');
    await prefs.setInt(_mahasiswaNomorProdiKey, mahasiswa['nomorProdi'] ?? 0);
    await prefs.setString(_mahasiswaNamaKey, mahasiswa['nama']?.toString() ?? '');
  }

  static Future<void> _saveDosenData(Map<String, dynamic> dosen, SharedPreferences prefs) async {
    await prefs.setInt(_dosenIdKey, dosen['id'] ?? 0);
    await prefs.setInt(_dosenUserIdKey, dosen['userId'] ?? 0);
    await prefs.setString(_dosenNamaKey, dosen['nama']?.toString() ?? '');
    await prefs.setString(_dosenNipKey, dosen['nip']?.toString() ?? '');
  }

  static Future<void> _cleanupRoleData(String role, SharedPreferences prefs) async {
    if (role == 'mahasiswa') {
      await prefs.remove(_dosenIdKey);
      await prefs.remove(_dosenUserIdKey);
      await prefs.remove(_dosenNamaKey);
      await prefs.remove(_dosenNipKey);
    } else if (role == 'dosen') {
      await prefs.remove(_mahasiswaIdKey);
      await prefs.remove(_mahasiswaUserIdKey);
      await prefs.remove(_mahasiswaNimKey);
      await prefs.remove(_mahasiswaKelasKey);
      await prefs.remove(_mahasiswaProdiKey);
      await prefs.remove(_mahasiswaDiplomaKey);
      await prefs.remove(_mahasiswaTahunMasukKey);
      await prefs.remove(_mahasiswaNomorProdiKey);
      await prefs.remove(_mahasiswaNamaKey);
    }
  }

  static Future<void> _clearAuthData(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiresKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userEmailVerifiedKey);
    await prefs.remove(_verificationCodeKey);
    await prefs.remove(_verificationCodeExpiresKey);

    // Clear new photo fields
    await prefs.remove(_userPhotoKey);
    await prefs.remove(_userPhotoUrlKey);

    // Clear role-specific data
    await prefs.remove(_mahasiswaIdKey);
    await prefs.remove(_mahasiswaUserIdKey);
    await prefs.remove(_mahasiswaNimKey);
    await prefs.remove(_mahasiswaKelasKey);
    await prefs.remove(_mahasiswaProdiKey);
    await prefs.remove(_mahasiswaDiplomaKey);
    await prefs.remove(_mahasiswaTahunMasukKey);
    await prefs.remove(_mahasiswaNomorProdiKey);
    await prefs.remove(_mahasiswaNamaKey);

    await prefs.remove(_dosenIdKey);
    await prefs.remove(_dosenUserIdKey);
    await prefs.remove(_dosenNamaKey);
    await prefs.remove(_dosenNipKey);
  }

  static Map<String, dynamic> _convertToStringMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map<dynamic, dynamic>) {
      return data.cast<String, dynamic>();
    } else if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        result[key.toString()] = value;
      });
      return result;
    }
    return {};
  }

  static dynamic _extractResponseData(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    } else if (data is Map) {
      return data;
    }
    return data;
  }

  static Future<void> _fallbackSaveMahasiswa(String nim, String prodi, String kelas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mahasiswaNimKey, nim);
      await prefs.setString(_mahasiswaProdiKey, prodi);
      await prefs.setString(_mahasiswaKelasKey, kelas);
      print("✅ Fallback: SharedPreferences updated using parameters");
    } catch (fallbackError) {
      print("❌ Fallback also failed: $fallbackError");
    }
  }

  // Emergency logout method
  static Future<void> emergencyLogout() async {
    print('🚨 Emergency logout - clearing all auth data');
    final prefs = await SharedPreferences.getInstance();
    await _clearAuthData(prefs);
    print('✅ All auth data cleared');
  }
}
