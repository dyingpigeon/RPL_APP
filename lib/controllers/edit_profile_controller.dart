// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/edit_profile_model.dart';
// import '../services/auth_service.dart';

// class EditProfileController with ChangeNotifier {
//   EditProfileModel _model = EditProfileModel();
//   final Color primaryRed = const Color(0xFFB71C1C);

//   EditProfileModel get model => _model;

//   // TextEditing controllers untuk form handling
//   final TextEditingController namaController = TextEditingController();
//   final TextEditingController nimController = TextEditingController();
//   final TextEditingController kelasController = TextEditingController();
//   final TextEditingController prodiController = TextEditingController();
//   final TextEditingController nipController = TextEditingController();

//   String? _userPhotoUrl;
//   bool _isDisposed = false;

//   // GlobalKey untuk ScaffoldMessenger
//   final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

//   // Navigator Key - TAMBAHKAN INI
//   static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   EditProfileController() {
//     _loadUserData();
//     _debugCheckSharedPreferences();
//   }

//   String? get userPhotoUrl => _userPhotoUrl;
//   bool get hasProfilePhoto => _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty;

//   @override
//   void dispose() {
//     _isDisposed = true;
//     namaController.dispose();
//     nimController.dispose();
//     kelasController.dispose();
//     prodiController.dispose();
//     nipController.dispose();
//     super.dispose();
//   }

//   void _debugCheckSharedPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     print("=== DEBUG SharedPreferences ===");
//     print("user_id: ${prefs.getInt('user_id')}");
//     print("userName: ${prefs.getString('userName')}");
//     print("userRole: ${prefs.getString('userRole')}");
//     print("user_photo_url: ${prefs.getString('user_photo_url')}");

//     final role = prefs.getString('userRole');
//     if (role == 'mahasiswa') {
//       print("mahasiswa_id: ${prefs.getInt('mahasiswa_id')}");
//       print("mahasiswa_nim: ${prefs.getString('mahasiswa_nim')}");
//       print("mahasiswa_kelas: ${prefs.getString('mahasiswa_kelas')}");
//       print("mahasiswa_prodi: ${prefs.getString('mahasiswa_prodi')}");
//     } else if (role == 'dosen') {
//       print("dosen_id: ${prefs.getInt('dosen_id')}");
//       print("dosen_nama: ${prefs.getString('dosen_nama')}");
//       print("dosen_nip: ${prefs.getString('dosen_nip')}");
//     }
//     print("===============================");
//   }

//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final role = prefs.getString('userRole') ?? 'mahasiswa';

//     // Load foto profile dari SharedPreferences
//     _userPhotoUrl = prefs.getString('user_photo_url');

//     // Update model dengan semua data termasuk photoUrl
//     _model = _model.copyWith(userRole: role, userId: prefs.getInt('user_id'), photoUrl: _userPhotoUrl);

//     namaController.text = prefs.getString('userName') ?? '';

//     // Load data berdasarkan role
//     if (role == 'mahasiswa') {
//       _model = _model.copyWith(
//         mahasiswaId: prefs.getInt('mahasiswa_id'),
//         nim: prefs.getString('mahasiswa_nim') ?? '',
//         kelas: prefs.getString('mahasiswa_kelas') ?? '',
//         prodi: prefs.getString('mahasiswa_prodi') ?? '',
//       );
//       nimController.text = prefs.getString('mahasiswa_nim') ?? '';
//       kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
//       prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
//     } else if (role == 'dosen') {
//       _model = _model.copyWith(dosenId: prefs.getInt('dosen_id'), nip: prefs.getString('dosen_nip') ?? '');
//       nipController.text = prefs.getString('dosen_nip') ?? '';
//     }

//     if (!_isDisposed) notifyListeners();
//   }

//   // Validasi form sebelum menyimpan
//   bool validateForm() {
//     if (namaController.text.isEmpty) {
//       return false;
//     }

//     if (_model.isMahasiswa) {
//       if (nimController.text.isEmpty || kelasController.text.isEmpty) {
//         return false;
//       }
//     }

//     if (_model.isDosen && nipController.text.isEmpty) {
//       return false;
//     }

//     return true;
//   }

//   // Cek apakah ada perubahan data
//   Future<bool> get hasChanges async {
//     final prefs = await SharedPreferences.getInstance();
//     final currentName = prefs.getString('userName') ?? '';

//     if (_model.isMahasiswa) {
//       final currentNim = prefs.getString('mahasiswa_nim') ?? '';
//       final currentKelas = prefs.getString('mahasiswa_kelas') ?? '';

//       return namaController.text != currentName ||
//           nimController.text != currentNim ||
//           kelasController.text != currentKelas;
//     } else {
//       final currentNip = prefs.getString('dosen_nip') ?? '';
//       return namaController.text != currentName || nipController.text != currentNip;
//     }
//   }

//   Future<void> saveProfile() async {
//     // Validasi form
//     if (!validateForm()) {
//       _showSnackBar("Harap isi semua field yang wajib diisi!");
//       return;
//     }

//     // Cek perubahan data
//     final hasDataChanges = await hasChanges;
//     if (!hasDataChanges) {
//       _showSnackBar("Tidak ada perubahan data untuk disimpan");
//       return;
//     }

//     if (!_model.hasUserData) {
//       _showSnackBar("ID User tidak ditemukan!");
//       return;
//     }

//     _model = _model.copyWith(isLoading: true);
//     if (!_isDisposed) notifyListeners();

//     try {
//       if (_model.isMahasiswa) {
//         await _saveMahasiswaProfile();
//       } else if (_model.isDosen) {
//         await _saveDosenProfile();
//       }
//     } catch (e) {
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();
//       _showSnackBar("Terjadi kesalahan: ${e.toString()}");
//     }
//   }

//   Future<void> _saveMahasiswaProfile() async {
//     if (!_model.hasMahasiswaData) {
//       _showSnackBar("ID Mahasiswa tidak ditemukan!");
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();
//       return;
//     }

//     try {
//       // Update model dengan data terbaru dari controller
//       _model = _model.copyWith(
//         nama: namaController.text,
//         nim: nimController.text,
//         kelas: kelasController.text,
//         prodi: prodiController.text,
//       );

//       // Jalankan kedua update secara berurutan
//       final resultMahasiswa = await AuthService.updateMahasiswa(
//         id: _model.mahasiswaId!,
//         idu: _model.userId!,
//         nama: namaController.text,
//         nim: nimController.text,
//         prodi: prodiController.text,
//         kelas: kelasController.text,
//       );

//       final resultUser = await AuthService.updateUser(idu: _model.userId!, nama: namaController.text);

//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();

//       // Cek hasil kedua request
//       bool mahasiswaSuccess = resultMahasiswa['statusCode'] == 200;
//       bool userSuccess = resultUser['statusCode'] == 200;

//       if (mahasiswaSuccess && userSuccess) {
//         _showSuccessSnackBar("Profil mahasiswa berhasil diperbarui");
//         // Reload data untuk update terbaru
//         await _loadUserData();
//       } else if (mahasiswaSuccess) {
//         _showSnackBar("Profil mahasiswa berhasil, tapi profil user gagal");
//       } else if (userSuccess) {
//         _showSnackBar("Profil user berhasil, tapi profil mahasiswa gagal");
//       } else {
//         String errorMessage = "Kedua update gagal: ";
//         if (resultMahasiswa['data']?['message'] != null) {
//           errorMessage += "Mahasiswa: ${resultMahasiswa['data']['message']} ";
//         }
//         if (resultUser['data']?['message'] != null) {
//           errorMessage += "User: ${resultUser['data']['message']}";
//         }
//         _showSnackBar(errorMessage.isEmpty ? "Unknown error" : errorMessage);
//       }
//     } catch (e) {
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();
//       _showSnackBar("Error saat menyimpan profil: ${e.toString()}");
//     }
//   }

//   Future<void> _saveDosenProfile() async {
//     if (!_model.hasDosenData) {
//       _showSnackBar("ID Dosen tidak ditemukan!");
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();
//       return;
//     }

//     try {
//       // Update model dengan data terbaru dari controller
//       _model = _model.copyWith(nama: namaController.text, nip: nipController.text);

//       // Update data dosen
//       final resultDosen = await AuthService.updateDosen(
//         id: _model.dosenId!,
//         nama: namaController.text,
//         nip: nipController.text,
//       );

//       // Update data user (nama)
//       final resultUser = await AuthService.updateUser(idu: _model.userId!, nama: namaController.text);

//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();

//       // Cek hasil kedua request
//       bool dosenSuccess = resultDosen['statusCode'] == 200;
//       bool userSuccess = resultUser['statusCode'] == 200;

//       if (dosenSuccess && userSuccess) {
//         _showSuccessSnackBar("Profil dosen berhasil diperbarui");
//         // Reload data untuk update terbaru
//         await _loadUserData();
//       } else if (dosenSuccess) {
//         _showSnackBar("Profil dosen berhasil, tapi profil user gagal");
//       } else if (userSuccess) {
//         _showSnackBar("Profil user berhasil, tapi profil dosen gagal");
//       } else {
//         String errorMessage = "Kedua update gagal: ";
//         if (resultDosen['data']?['message'] != null) {
//           errorMessage += "Dosen: ${resultDosen['data']['message']} ";
//         }
//         if (resultUser['data']?['message'] != null) {
//           errorMessage += "User: ${resultUser['data']['message']}";
//         }
//         _showSnackBar(errorMessage.isEmpty ? "Unknown error" : errorMessage);
//       }
//     } catch (e) {
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();
//       _showSnackBar("Error saat menyimpan profil: ${e.toString()}");
//     }
//   }

//   void showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
//           content: const Text("Apakah Anda yakin ingin keluar?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Batal"),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _performLogout();
//               },
//               child: const Text("Ya", style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _performLogout() async {
//     _model = _model.copyWith(isLoading: true);
//     if (!_isDisposed) notifyListeners();

//     try {
//       await AuthService.logout();
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();

//       // ✅ GUNAKAN NAVIGATOR KEY - Lebih aman
//       navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
//     } catch (e) {
//       _model = _model.copyWith(isLoading: false);
//       if (!_isDisposed) notifyListeners();

//       _showSnackBar("Error saat logout: ${e.toString()}");
//     }
//   }

//   // Snackbar methods menggunakan GlobalKey
//   void _showSnackBar(String message) {
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: primaryRed, duration: const Duration(seconds: 3)),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
//     );
//   }

//   String getRoleDisplayName() {
//     return _model.isMahasiswa ? 'Mahasiswa' : 'Dosen';
//   }

//   String getSaveButtonText() {
//     return "Simpan Profil ${getRoleDisplayName()}";
//   }

//   // Method untuk refresh data
//   Future<void> refreshUserData() async {
//     await _loadUserData();
//   }

//   // Method untuk clear form (optional)
//   void clearForm() {
//     namaController.clear();
//     nimController.clear();
//     kelasController.clear();
//     prodiController.clear();
//     nipController.clear();
//     if (!_isDisposed) notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/edit_profile_model.dart';
import '../services/auth_service.dart';
import '../utils/pemission_handler.dart'; // Pastikan path benar

class EditProfileController with ChangeNotifier {
  EditProfileModel _model = EditProfileModel();
  final Color primaryRed = const Color(0xFFB71C1C);

  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();

  EditProfileModel get model => _model;

  // TextEditing controllers untuk form handling
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController prodiController = TextEditingController();
  final TextEditingController nipController = TextEditingController();

  String? _userPhotoUrl;
  bool _isDisposed = false;
  bool _isUpdatingPhoto = false;

  // GlobalKey untuk ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Navigator Key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  EditProfileController() {
    _loadUserData();
    _debugCheckSharedPreferences();
  }

  String? get userPhotoUrl => _userPhotoUrl;
  bool get hasProfilePhoto => _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty;
  bool get isUpdatingPhoto => _isUpdatingPhoto;

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

  // ============================
  // PHOTO UPDATE METHODS - DIPERBAIKI
  // ============================

  // Di EditProfileController - UPDATE METHOD PHOTO
  // Di EditProfileController - OPTIMIZED FOR ANDROID 11+
  Future<void> pickImageFromGallery() async {
    try {
      print('📱 Starting gallery pick process...');

      // Debug permissions terlebih dahulu
      await AppPermissionHandler.debugPermissions();

      // ✅ CHECK SPECIAL: Android 11+ tidak butuh permission
      final isAndroid11Plus = await AppPermissionHandler.canAccessGalleryWithoutPermission();

      if (isAndroid11Plus) {
        print('✅ Android 11+ - No permission needed, opening gallery directly');
        // Langsung buka gallery tanpa permission check
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          await _updateProfilePhoto(pickedFile.path);
        }
        return;
      }

      // ❌ Android <11 butuh permission check
      print('📱 Android <11 - Checking permissions...');
      final permissions = await AppPermissionHandler.checkPhotoPermissions();
      final hasPermission = permissions['gallery'] == true;

      print('🔐 Gallery permission status: $hasPermission');

      if (!hasPermission) {
        print('🔐 Permission not granted, requesting...');
        final newPermissions = await AppPermissionHandler.requestPhotoPermissions();
        final hasNewPermission = newPermissions['gallery'] == true;

        if (!hasNewPermission) {
          _showSnackBar("Izin akses gallery diperlukan untuk memilih foto");
          _showPermissionSettingsDialog("Gallery");
          return;
        }
      }

      print('✅ Permission granted, opening gallery...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _updateProfilePhoto(pickedFile.path);
      }
    } catch (e) {
      print('❌ Gallery pick error: $e');
      _showSnackBar("Gagal membuka gallery: ${e.toString()}");
    }
  }

  /// Mengambil foto dari kamera dengan permission check
  Future<void> takePhotoFromCamera() async {
    try {
      print('📱 Checking camera permission...');

      // Check camera permission
      final hasPermission = await _checkCameraPermission();

      if (!hasPermission) {
        _showSnackBar("Izin akses kamera diperlukan untuk mengambil foto");
        _showPermissionSettingsDialog("Kamera");
        return;
      }

      print('✅ Camera permission granted, opening camera...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        print('📸 Photo taken: ${pickedFile.path}');
        await _updateProfilePhoto(pickedFile.path);
      } else {
        print('ℹ️ User cancelled camera');
      }
    } catch (e) {
      print('❌ Camera pick error: $e');

      if (e.toString().contains('PERMISSION_DENIED') || e.toString().contains('permission')) {
        _showSnackBar("Izin akses kamera ditolak");
        _showPermissionSettingsDialog("Kamera");
      } else {
        _showSnackBar("Gagal mengambil foto: ${e.toString()}");
      }
    }
  }

  /// Check camera permission khusus
  Future<bool> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;

      // Request permission jika belum granted
      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (e) {
      print('❌ Camera permission check error: $e');
      return false;
    }
  }

  /// Mengupdate foto profil ke server
  Future<void> _updateProfilePhoto(String photoPath) async {
    if (!_model.hasUserData) {
      _showSnackBar("ID User tidak ditemukan!");
      return;
    }

    _isUpdatingPhoto = true;
    if (!_isDisposed) notifyListeners();

    try {
      final result = await AuthService.updateUserPhoto(
        userId: _model.userId!,
        name: namaController.text,
        photoPath: photoPath,
      );

      if (result['success'] == true) {
        _showSuccessSnackBar("Foto profil berhasil diupdate");

        // Refresh data untuk mendapatkan URL foto terbaru
        await _loadUserData();

        // Tambahkan delay kecil untuk memastikan data terload
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _showSnackBar(result['message'] ?? "Gagal mengupdate foto profil");
      }
    } catch (e) {
      print('❌ Error updating photo: $e');
      _showSnackBar("Error mengupdate foto: ${e.toString()}");
    } finally {
      _isUpdatingPhoto = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Menampilkan dialog pilihan sumber foto
  void showPhotoSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Pilih Sumber Foto", style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
          content: const Text("Dari mana Anda ingin mengambil foto?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImageFromGallery();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.photo_library), SizedBox(width: 8), Text("Gallery")],
              ),
            ),
            // males bused
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     takePhotoFromCamera();
            //   },
            //   child: const Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [Icon(Icons.camera_alt), SizedBox(width: 8), Text("Kamera")],
            //   ),
            // ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
          ],
        );
      },
    );
  }

  void _showPermissionSettingsDialog(String permissionType) {
    if (navigatorKey.currentContext == null) {
      _showSnackBar("Izin $permissionType diperlukan. Buka pengaturan aplikasi untuk memberikan izin.");
      return;
    }

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Izin $permissionType Diperlukan"),
          content: Text(
            "Aplikasi membutuhkan akses $permissionType "
            "untuk mengupload foto profil. Silakan berikan izin melalui pengaturan.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Nanti")),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ✅ Direct call ke openAppSettings
                openAppSettings();
              },
              child: const Text("Buka Pengaturan"),
            ),
          ],
        );
      },
    );
  }

  // ============================
  // EXISTING METHODS (Tetap Dipertahankan)
  // ============================

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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
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

  // Dialog untuk membuka settings - TANPA PARAMETER CONTEXT
  // void _showPermissionSettingsDialog(String permissionType) {
  //   // Karena kita tidak punya context di sini, gunakan navigatorKey
  //   if (navigatorKey.currentContext == null) {
  //     _showSnackBar(
  //       "Izin ${permissionType == 'camera' ? 'kamera' : 'gallery'} diperlukan. Silakan berikan izin melalui pengaturan aplikasi.",
  //     );
  //     return;
  //   }

  //   showDialog(
  //     context: navigatorKey.currentContext!,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //         title: Text("Izin ${permissionType == 'camera' ? 'Kamera' : 'Gallery'} Diperlukan"),
  //         content: Text(
  //           "Aplikasi membutuhkan akses ${permissionType == 'camera' ? 'kamera' : 'gallery'} "
  //           "untuk mengupload foto profil. Silakan berikan izin melalui pengaturan.",
  //         ),
  //         actions: [
  //           TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Nanti")),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               AppPermissionHandler.openAppSettings();
  //             },
  //             child: const Text("Buka Pengaturan"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }