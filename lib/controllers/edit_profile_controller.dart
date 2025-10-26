import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/edit_profile_model.dart';
import '../services/auth_service.dart';

class EditProfileController with ChangeNotifier {
  EditProfileModel _model = EditProfileModel();
  final Color primaryRed = const Color(0xFFB71C1C);

  EditProfileModel get model => _model;

  // TextEditing controllers untuk form handling
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController prodiController = TextEditingController();
  final TextEditingController nipController = TextEditingController();

  String? _userPhotoUrl;
  bool _isDisposed = false;

  // GlobalKey untuk ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Navigator Key - TAMBAHKAN INI
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  EditProfileController() {
    _loadUserData();
    _debugCheckSharedPreferences();
  }

  String? get userPhotoUrl => _userPhotoUrl;
  bool get hasProfilePhoto => _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty;

  @override
  void dispose() {
    _isDisposed = true;
    namaController.dispose();
    nimController.dispose();
    kelasController.dispose();
    prodiController.dispose();
    nipController.dispose();
    super.dispose();
  }

  void _debugCheckSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== DEBUG SharedPreferences ===");
    print("user_id: ${prefs.getInt('user_id')}");
    print("userName: ${prefs.getString('userName')}");
    print("userRole: ${prefs.getString('userRole')}");
    print("user_photo_url: ${prefs.getString('user_photo_url')}");

    final role = prefs.getString('userRole');
    if (role == 'mahasiswa') {
      print("mahasiswa_id: ${prefs.getInt('mahasiswa_id')}");
      print("mahasiswa_nim: ${prefs.getString('mahasiswa_nim')}");
      print("mahasiswa_kelas: ${prefs.getString('mahasiswa_kelas')}");
      print("mahasiswa_prodi: ${prefs.getString('mahasiswa_prodi')}");
    } else if (role == 'dosen') {
      print("dosen_id: ${prefs.getInt('dosen_id')}");
      print("dosen_nama: ${prefs.getString('dosen_nama')}");
      print("dosen_nip: ${prefs.getString('dosen_nip')}");
    }
    print("===============================");
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'mahasiswa';

    // Load foto profile dari SharedPreferences
    _userPhotoUrl = prefs.getString('user_photo_url');

    // Update model dengan semua data termasuk photoUrl
    _model = _model.copyWith(userRole: role, userId: prefs.getInt('user_id'), photoUrl: _userPhotoUrl);

    namaController.text = prefs.getString('userName') ?? '';

    // Load data berdasarkan role
    if (role == 'mahasiswa') {
      _model = _model.copyWith(
        mahasiswaId: prefs.getInt('mahasiswa_id'),
        nim: prefs.getString('mahasiswa_nim') ?? '',
        kelas: prefs.getString('mahasiswa_kelas') ?? '',
        prodi: prefs.getString('mahasiswa_prodi') ?? '',
      );
      nimController.text = prefs.getString('mahasiswa_nim') ?? '';
      kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
      prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
    } else if (role == 'dosen') {
      _model = _model.copyWith(dosenId: prefs.getInt('dosen_id'), nip: prefs.getString('dosen_nip') ?? '');
      nipController.text = prefs.getString('dosen_nip') ?? '';
    }

    if (!_isDisposed) notifyListeners();
  }

  // Validasi form sebelum menyimpan
  bool validateForm() {
    if (namaController.text.isEmpty) {
      return false;
    }

    if (_model.isMahasiswa) {
      if (nimController.text.isEmpty || kelasController.text.isEmpty) {
        return false;
      }
    }

    if (_model.isDosen && nipController.text.isEmpty) {
      return false;
    }

    return true;
  }

  // Cek apakah ada perubahan data
  Future<bool> get hasChanges async {
    final prefs = await SharedPreferences.getInstance();
    final currentName = prefs.getString('userName') ?? '';

    if (_model.isMahasiswa) {
      final currentNim = prefs.getString('mahasiswa_nim') ?? '';
      final currentKelas = prefs.getString('mahasiswa_kelas') ?? '';

      return namaController.text != currentName ||
          nimController.text != currentNim ||
          kelasController.text != currentKelas;
    } else {
      final currentNip = prefs.getString('dosen_nip') ?? '';
      return namaController.text != currentName || nipController.text != currentNip;
    }
  }

  Future<void> saveProfile() async {
    // Validasi form
    if (!validateForm()) {
      _showSnackBar("Harap isi semua field yang wajib diisi!");
      return;
    }

    // Cek perubahan data
    final hasDataChanges = await hasChanges;
    if (!hasDataChanges) {
      _showSnackBar("Tidak ada perubahan data untuk disimpan");
      return;
    }

    if (!_model.hasUserData) {
      _showSnackBar("ID User tidak ditemukan!");
      return;
    }

    _model = _model.copyWith(isLoading: true);
    if (!_isDisposed) notifyListeners();

    try {
      if (_model.isMahasiswa) {
        await _saveMahasiswaProfile();
      } else if (_model.isDosen) {
        await _saveDosenProfile();
      }
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();
      _showSnackBar("Terjadi kesalahan: ${e.toString()}");
    }
  }

  Future<void> _saveMahasiswaProfile() async {
    if (!_model.hasMahasiswaData) {
      _showSnackBar("ID Mahasiswa tidak ditemukan!");
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();
      return;
    }

    try {
      // Update model dengan data terbaru dari controller
      _model = _model.copyWith(
        nama: namaController.text,
        nim: nimController.text,
        kelas: kelasController.text,
        prodi: prodiController.text,
      );

      // Jalankan kedua update secara berurutan
      final resultMahasiswa = await AuthService.updateMahasiswa(
        id: _model.mahasiswaId!,
        idu: _model.userId!,
        nama: namaController.text,
        nim: nimController.text,
        prodi: prodiController.text,
        kelas: kelasController.text,
      );

      final resultUser = await AuthService.updateUser(idu: _model.userId!, nama: namaController.text);

      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();

      // Cek hasil kedua request
      bool mahasiswaSuccess = resultMahasiswa['statusCode'] == 200;
      bool userSuccess = resultUser['statusCode'] == 200;

      if (mahasiswaSuccess && userSuccess) {
        _showSuccessSnackBar("Profil mahasiswa berhasil diperbarui");
        // Reload data untuk update terbaru
        await _loadUserData();
      } else if (mahasiswaSuccess) {
        _showSnackBar("Profil mahasiswa berhasil, tapi profil user gagal");
      } else if (userSuccess) {
        _showSnackBar("Profil user berhasil, tapi profil mahasiswa gagal");
      } else {
        String errorMessage = "Kedua update gagal: ";
        if (resultMahasiswa['data']?['message'] != null) {
          errorMessage += "Mahasiswa: ${resultMahasiswa['data']['message']} ";
        }
        if (resultUser['data']?['message'] != null) {
          errorMessage += "User: ${resultUser['data']['message']}";
        }
        _showSnackBar(errorMessage.isEmpty ? "Unknown error" : errorMessage);
      }
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();
      _showSnackBar("Error saat menyimpan profil: ${e.toString()}");
    }
  }

  Future<void> _saveDosenProfile() async {
    if (!_model.hasDosenData) {
      _showSnackBar("ID Dosen tidak ditemukan!");
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();
      return;
    }

    try {
      // Update model dengan data terbaru dari controller
      _model = _model.copyWith(nama: namaController.text, nip: nipController.text);

      // Update data dosen
      final resultDosen = await AuthService.updateDosen(
        id: _model.dosenId!,
        nama: namaController.text,
        nip: nipController.text,
      );

      // Update data user (nama)
      final resultUser = await AuthService.updateUser(idu: _model.userId!, nama: namaController.text);

      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();

      // Cek hasil kedua request
      bool dosenSuccess = resultDosen['statusCode'] == 200;
      bool userSuccess = resultUser['statusCode'] == 200;

      if (dosenSuccess && userSuccess) {
        _showSuccessSnackBar("Profil dosen berhasil diperbarui");
        // Reload data untuk update terbaru
        await _loadUserData();
      } else if (dosenSuccess) {
        _showSnackBar("Profil dosen berhasil, tapi profil user gagal");
      } else if (userSuccess) {
        _showSnackBar("Profil user berhasil, tapi profil dosen gagal");
      } else {
        String errorMessage = "Kedua update gagal: ";
        if (resultDosen['data']?['message'] != null) {
          errorMessage += "Dosen: ${resultDosen['data']['message']} ";
        }
        if (resultUser['data']?['message'] != null) {
          errorMessage += "User: ${resultUser['data']['message']}";
        }
        _showSnackBar(errorMessage.isEmpty ? "Unknown error" : errorMessage);
      }
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();
      _showSnackBar("Error saat menyimpan profil: ${e.toString()}");
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    _model = _model.copyWith(isLoading: true);
    if (!_isDisposed) notifyListeners();

    try {
      await AuthService.logout();
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();

      // ✅ GUNAKAN NAVIGATOR KEY - Lebih aman
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      if (!_isDisposed) notifyListeners();

      _showSnackBar("Error saat logout: ${e.toString()}");
    }
  }

  // Snackbar methods menggunakan GlobalKey
  void _showSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryRed, duration: const Duration(seconds: 3)),
    );
  }

  void _showSuccessSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
    );
  }

  String getRoleDisplayName() {
    return _model.isMahasiswa ? 'Mahasiswa' : 'Dosen';
  }

  String getSaveButtonText() {
    return "Simpan Profil ${getRoleDisplayName()}";
  }

  // Method untuk refresh data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  // Method untuk clear form (optional)
  void clearForm() {
    namaController.clear();
    nimController.clear();
    kelasController.clear();
    prodiController.clear();
    nipController.clear();
    if (!_isDisposed) notifyListeners();
  }
}
