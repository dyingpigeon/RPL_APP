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

  EditProfileController() {
    _loadUserData();
    _debugCheckSharedPreferences();
  }

  void _debugCheckSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== DEBUG SharedPreferences ===");
    print("user_id: ${prefs.getInt('user_id')}");
    print("userName: ${prefs.getString('userName')}");
    print("userRole: ${prefs.getString('userRole')}");

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

  // Future<void> _loadUserData() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   // Dapatkan role user
  //   final role = prefs.getString('userRole') ?? 'mahasiswa';

  //   _model = _model.copyWith(userRole: role, userId: prefs.getInt('user_id'));

  //   namaController.text = prefs.getString('userName') ?? '';

  //   // Load data berdasarkan role
  //   if (role == 'mahasiswa') {
  //     _model = _model.copyWith(mahasiswaId: prefs.getInt('mahasiswa_id'));
  //     nimController.text = prefs.getString('mahasiswa_nim') ?? '';
  //     kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
  //     prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
  //   } else if (role == 'dosen') {
  //     _model = _model.copyWith(dosenId: prefs.getInt('dosen_id'));
  //     nipController.text = prefs.getString('dosen_nip') ?? '';
  //   }

  //   notifyListeners();
  // }

  Future<void> saveProfile(BuildContext context) async {
    if (!_model.hasUserData) {
      _showSnackBar(context, "ID User tidak ditemukan!");
      return;
    }

    _model = _model.copyWith(isLoading: true);
    notifyListeners();

    try {
      if (_model.isMahasiswa) {
        await _saveMahasiswaProfile(context);
      } else if (_model.isDosen) {
        await _saveDosenProfile(context);
      }
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
      _showSnackBar(context, "Error: $e");
    }
  }

  Future<void> _saveMahasiswaProfile(BuildContext context) async {
    if (!_model.hasMahasiswaData) {
      _showSnackBar(context, "ID Mahasiswa tidak ditemukan!");
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

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
    notifyListeners();

    // Cek hasil kedua request
    bool mahasiswaSuccess = resultMahasiswa['statusCode'] == 200;
    bool userSuccess = resultUser['statusCode'] == 200;

    if (mahasiswaSuccess && userSuccess) {
      _showSnackBar(context, "Profil mahasiswa berhasil diperbarui");
    } else if (mahasiswaSuccess) {
      _showSnackBar(context, "Profil mahasiswa berhasil, tapi profil user gagal");
    } else if (userSuccess) {
      _showSnackBar(context, "Profil user berhasil, tapi profil mahasiswa gagal");
    } else {
      String errorMessage = "Kedua update gagal: ";
      if (resultMahasiswa['data']?['message'] != null) {
        errorMessage += "Mahasiswa: ${resultMahasiswa['data']['message']} ";
      }
      if (resultUser['data']?['message'] != null) {
        errorMessage += "User: ${resultUser['data']['message']}";
      }
      _showSnackBar(context, errorMessage.isEmpty ? "Unknown error" : errorMessage);
    }
  }

  Future<void> _saveDosenProfile(BuildContext context) async {
    if (!_model.hasDosenData) {
      _showSnackBar(context, "ID Dosen tidak ditemukan!");
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    // Update data dosen
    final resultDosen = await AuthService.updateDosen(
      id: _model.dosenId!,
      nama: namaController.text,
      nip: nipController.text,
    );

    // Update data user (nama)
    final resultUser = await AuthService.updateUser(idu: _model.userId!, nama: namaController.text);

    _model = _model.copyWith(isLoading: false);
    notifyListeners();

    // Cek hasil kedua request
    bool dosenSuccess = resultDosen['statusCode'] == 200;
    bool userSuccess = resultUser['statusCode'] == 200;

    if (dosenSuccess && userSuccess) {
      _showSnackBar(context, "Profil dosen berhasil diperbarui");
    } else if (dosenSuccess) {
      _showSnackBar(context, "Profil dosen berhasil, tapi profil user gagal");
    } else if (userSuccess) {
      _showSnackBar(context, "Profil user berhasil, tapi profil dosen gagal");
    } else {
      String errorMessage = "Kedua update gagal: ";
      if (resultDosen['data']?['message'] != null) {
        errorMessage += "Dosen: ${resultDosen['data']['message']} ";
      }
      if (resultUser['data']?['message'] != null) {
        errorMessage += "User: ${resultUser['data']['message']}";
      }
      _showSnackBar(context, errorMessage.isEmpty ? "Unknown error" : errorMessage);
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
                await AuthService.logout();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryRed, duration: const Duration(seconds: 3)));
  }

  String getRoleDisplayName() {
    return _model.isMahasiswa ? 'Mahasiswa' : 'Dosen';
  }

  String getSaveButtonText() {
    return "Simpan Profil ${getRoleDisplayName()}";
  }

  String? _userPhotoUrl;

  String? get userPhotoUrl => _userPhotoUrl;

  // Update _loadUserData method
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'mahasiswa';

    _model = _model.copyWith(userRole: role, userId: prefs.getInt('user_id'));

    namaController.text = prefs.getString('userName') ?? '';

    // LOAD FOTO PROFILE dari SharedPreferences
    _userPhotoUrl = prefs.getString('user_photo_url');

    // Load data berdasarkan role
    if (role == 'mahasiswa') {
      _model = _model.copyWith(mahasiswaId: prefs.getInt('mahasiswa_id'));
      nimController.text = prefs.getString('mahasiswa_nim') ?? '';
      kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
      prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
    } else if (role == 'dosen') {
      _model = _model.copyWith(dosenId: prefs.getInt('dosen_id'));
      nipController.text = prefs.getString('dosen_nip') ?? '';
    }

    notifyListeners();
  }

  // Method untuk check jika ada foto
  bool get hasProfilePhoto => _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty;

  @override
  void dispose() {
    namaController.dispose();
    nimController.dispose();
    kelasController.dispose();
    prodiController.dispose();
    nipController.dispose();
    super.dispose();
  }
}
