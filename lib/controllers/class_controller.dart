import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/auth_service.dart';
import '../services/jadwal_service.dart';
import '../ui/class_detail_page.dart';

class ClassController with ChangeNotifier {
  ClassModel _model = ClassModel();
  final Color primaryRed = const Color(0xFFB71C1C);

  ClassModel get model => _model;

  ClassController() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await fetchJadwal();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await AuthService.getUserName();
      final role = await AuthService.getUserRole();

      _model = _model.copyWith(
        userName: name ?? "User",
        userRole: role ?? "mahasiswa",
      );
      notifyListeners();

      print("👤 User data loaded - Name: ${_model.userName}, Role: ${_model.userRole}");
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> fetchJadwal() async {
    try {
      _model = _model.copyWith(
        isLoading: true,
        errorMessage: null,
      );
      notifyListeners();

      print("🔄 Fetching jadwal untuk role: ${_model.userRole}");

      final List<Map<String, dynamic>> result = await JadwalService.fetchJadwal();

      if (result.isNotEmpty) {
        _model = _model.copyWith(
          jadwalList: result,
          isLoading: false,
        );
        notifyListeners();
        print("✅ Berhasil load ${_model.jadwalList.length} jadwal untuk ${_model.userRole}");
      } else {
        _model = _model.copyWith(
          errorMessage: _model.errorTitle,
          isLoading: false,
        );
        notifyListeners();
      }
    } catch (e) {
      _model = _model.copyWith(
        errorMessage: "Terjadi kesalahan: $e",
        isLoading: false,
      );
      notifyListeners();
      print("❌ Error fetch jadwal: $e");
    }
  }

  Future<void> handleRefresh() async {
    print("🔄 Pull to refresh triggered");
    await _loadUserData();
    await fetchJadwal();
  }

  String formatFullDate(DateTime dt) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    String dayName = days[dt.weekday % 7];
    String monthName = months[dt.month - 1];
    return "$dayName, ${dt.day} $monthName ${dt.year}";
  }

  String getScheduleInfo(Map<String, dynamic> jadwal) {
    final String kelas = jadwal['kelas'] ?? "";
    final String hari = jadwal['hari'] ?? "";

    if (_model.isMahasiswa) {
      return "Kelas $kelas | ${hari.toUpperCase()}";
    } else {
      return "$kelas | ${hari.toUpperCase()}";
    }
  }

  void navigateToClassDetail(BuildContext context, Map<String, dynamic> jadwal) {
    final String title = jadwal['title'] ?? "Mata Kuliah";
    final String schedule = getScheduleInfo(jadwal);

    print('=== DEBUG: Data yang dikirim ke ClassDetail ===');
    print('Class Name: $title');
    print('Dosen: ${jadwal['dosen'] ?? "Dosen Tidak Diketahui"}');
    print('Dosen ID: ${jadwal['dosenId'] ?? 0}');
    print('Jadwal ID: ${jadwal['id'] ?? 0}');
    print('Hari: ${jadwal['hari'] ?? ""}');
    print('Kelas: ${jadwal['kelas'] ?? ""}');
    print('Ruangan: ${jadwal['ruangan'] ?? "-"}');
    print('Jam: ${jadwal['jamMulai'] ?? "-"} - ${jadwal['jamSelesai'] ?? "-"}');
    print('Role: ${_model.userRole}');
    print('============================================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetail(
          className: title,
          schedule: schedule,
          dosenId: jadwal['dosenId'] ?? 0,
          jadwalId: jadwal['id'] ?? 0,
        ),
      ),
    );
  }
}