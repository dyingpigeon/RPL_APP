import 'dart:async';
import 'package:flutter/material.dart';
import '../models/home_model.dart';
import '../services/jadwal_service.dart';
import '../services/auth_service.dart';
import '../services/tugas_service.dart';

class HomeController with ChangeNotifier {
  HomeModel _model = HomeModel();
  final Color primaryRed = const Color(0xFFC2000E);

  HomeModel get model => _model;

  late Timer _timer;

  HomeController() {
    _initializeTimer();
    _initializeData();
  }

  void _initializeTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _model = _model.copyWith(currentDate: DateTime.now());
      notifyListeners();
    });
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadJadwalAndTugas();
  }

  Future<void> _loadUserData() async {
    try {
      final name = await AuthService.getUserName();
      final role = await AuthService.getUserRole();

      _model = _model.copyWith(userName: name ?? "User", userRole: role ?? "mahasiswa");
      notifyListeners();
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadJadwalAndTugas() async {
    _model = _model.copyWith(isLoading: true);
    notifyListeners();

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print("User belum login");
        _model = _model.copyWith(isLoading: false);
        notifyListeners();
        return;
      }

      final futureMataKuliah = JadwalService.fetchJadwal();
      final futureTugas = TugasService.fetchTugas();

      final results = await Future.wait([futureMataKuliah, futureTugas]);

      _model = _model.copyWith(mataKuliah: results[0], tugas: results[1], isLoading: false);
      notifyListeners();
    } catch (e) {
      print("Error loading jadwal and tugas: $e");
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _loadJadwalAndTugas();
  }

  String formatFullDate(DateTime dt) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    String dayName = days[dt.weekday % 7];
    String monthName = months[dt.month - 1];
    return "$dayName, ${dt.day} $monthName ${dt.year}";
  }

  String getGreeting() {
    return _model.userRole == 'mahasiswa' ? 'Hi, ${_model.userName}!' : 'Selamat Mengajar, ${_model.userName}!';
  }

  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
