import 'package:elearning_rpl_5d/ui/class_detail_page.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../services/jadwal_service.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  // final int _selectedIndex = 1;

  late DateTime _today;
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String userName = "User";
  String userRole = "mahasiswa"; // default

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _loadUserData();
    fetchJadwal();
  }

  // Method baru: Load data user dan role
  Future<void> _loadUserData() async {
    try {
      final name = await AuthService.getUserName();
      final role = await AuthService.getUserRole();

      if (mounted) {
        setState(() {
          userName = name ?? "User";
          userRole = role ?? "mahasiswa";
        });
      }

      print("👤 User data loaded - Name: $userName, Role: $userRole");
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // Method fetch jadwal yang diperbarui
  Future<void> fetchJadwal() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print("🔄 Fetching jadwal untuk role: $userRole");

      final List<Map<String, dynamic>> result = await JadwalService.fetchJadwal();

      if (result.isNotEmpty) {
        setState(() {
          _jadwalList = result;
          _isLoading = false;
        });
        print("✅ Berhasil load ${_jadwalList.length} jadwal untuk $userRole");
      } else {
        setState(() {
          _errorMessage =
              userRole == 'mahasiswa'
                  ? "Tidak ada jadwal ditemukan untuk semester ini"
                  : "Tidak ada jadwal mengajar ditemukan";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
        _isLoading = false;
      });
      print("❌ Error fetch jadwal: $e");
    }
  }

  // Method untuk handle refresh
  Future<void> _handleRefresh() async {
    print("🔄 Pull to refresh triggered");
    await _loadUserData(); // Refresh user data juga
    await fetchJadwal(); // Refresh jadwal data
  }

  // Tampilan header yang berbeda berdasarkan role
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(_formatFullDate(_today), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
      ],
    );
  }

  // Tampilan card jadwal yang berbeda berdasarkan role
  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    final String title = jadwal['title'] ?? "Mata Kuliah";
    final String dosen = jadwal['dosen'] ?? "Dosen Tidak Diketahui";
    final String kelas = jadwal['kelas'] ?? "";
    final String hari = jadwal['hari'] ?? "";

    // Info tambahan berdasarkan role
    String scheduleInfo = "";
    if (userRole == 'mahasiswa') {
      scheduleInfo = "Kelas $kelas | ${hari.toUpperCase()}";
    } else {
      scheduleInfo = "$kelas | ${hari.toUpperCase()}";
    }

    return _classCard(
      title,
      dosen,
      scheduleInfo,
      primaryRed,
      jadwal['ruangan'] ?? '-',
      jadwal['jamMulai'] ?? '-',
      jadwal['jamSelesai'] ?? '-',
      jadwal['dosenId'] ?? 0,
      jadwal['id'] ?? 0,
      jadwal['hari'] ?? '',
      jadwal['kelas'] ?? '',
    );
  }

  // Widget untuk konten utama
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchJadwal,
                style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildHeader(),

        // List jadwal
        for (var jadwal in _jadwalList) _buildJadwalCard(jadwal),

        if (_jadwalList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    userRole == 'mahasiswa'
                        ? "Tidak ada jadwal kelas untuk semester ini"
                        : "Tidak ada jadwal mengajar untuk saat ini",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 70),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          userRole == 'mahasiswa' ? 'Hi, $userName!' : 'Selamat Mengajar, $userName!',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(radius: 18, backgroundImage: AssetImage("assets/profile.jpg")),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryRed,
        backgroundColor: Colors.white,
        child: _buildContent(),
      ),

      // bottomNavigationBar: ClipRRect(
      //   borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      //   child: BottomNavigationBar(
      //     backgroundColor: const Color(0xFFB71C1C),
      //     elevation: 0,
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //     selectedItemColor: Colors.white,
      //     unselectedItemColor: Colors.white70,
      //     items: const [
      //       BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //       BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
      //       BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      //     ],
      //   ),
      // ),
    );
  }

  String _formatFullDate(DateTime dt) {
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

  // void _onItemTapped(int index) {
  //   if (index == 0) {
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } else if (index == 1) {
  //     // tetap di Class Page
  //   } else if (index == 2) {
  //     Navigator.pushReplacementNamed(context, '/edit');
  //   }
  // }

  Widget _classCard(
    String title,
    String dosen,
    String schedule,
    Color primaryRed,
    String ruangan,
    String jamMulai,
    String jamSelesai,
    int dosenId,
    int jadwalId,
    String hari,
    String kelas,
  ) {
    return GestureDetector(
      onTap: () {
        print('=== DEBUG: Data yang dikirim ke ClassDetail ===');
        print('Class Name: $title');
        print('Dosen: $dosen');
        print('Dosen ID: $dosenId');
        print('Jadwal ID: $jadwalId');
        print('Hari: $hari');
        print('Kelas: $kelas');
        print('Ruangan: $ruangan');
        print('Jam: $jamMulai - $jamSelesai');
        print('Role: $userRole');
        print('============================================');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ClassDetail(className: title, schedule: schedule, dosenId: dosenId, jadwalId: jadwalId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border.all(color: primaryRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(dosen, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(schedule, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '$ruangan • $jamMulai - $jamSelesai',
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
