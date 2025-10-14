import 'package:elearning_rpl_5d/front/class_detail_page.dart';
import '../back/auth_service.dart';
import 'package:flutter/material.dart';
import '../back/jadwal_service.dart'; // Import JadwalService yang baru

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  int _selectedIndex = 1;

  late DateTime _today;
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String userName = "Mahasiswa"; // default sebelum fetch

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    fetchJadwal();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final name = await AuthService.getUserName();
      if (name != null && mounted) {
        setState(() {
          userName = name;
        });
      }
    } catch (e) {
      print("Error loading user name: $e");
    }
  }

  // 🔹 Fungsi ambil data jadwal dari JadwalService yang baru
  Future<void> fetchJadwal() async {
    try {
      final List<Map<String, dynamic>> result = await JadwalService.fetchAllJadwal();

      if (result.isNotEmpty) {
        setState(() {
          _jadwalList = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Tidak ada jadwal ditemukan untuk semester ini";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
        _isLoading = false;
      });
    }
  }

  // 🔹 Format tanggal seperti kode aslimu
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

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // tetap di Class Page
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatFullDate(_today);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text('Hi, $userName!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(radius: 18, backgroundImage: AssetImage("assets/profile.jpg")),
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              )
              : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  const SizedBox(height: 4),
                  Text(formattedDate, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),

                  // 🔹 Loop data dari API dengan struktur yang baru
                  // Dalam loop, tambahkan parameter dosenId
                  for (var jadwal in _jadwalList)
                    _classCard(
                      jadwal['title'] ?? "Mata Kuliah",
                      jadwal['dosen'] ?? "Dosen Tidak Diketahui", // ← String: nama dosen
                      "Kelas ${jadwal['kelas']} | ${jadwal['hari'].toString().toUpperCase()}",
                      primaryRed,
                      jadwal['ruangan'] ?? '-',
                      jadwal['jamMulai'] ?? '-',
                      jadwal['jamSelesai'] ?? '-',
                      jadwal['dosenId'] ?? 1, // ← int: ID dosen untuk navigasi
                      jadwal['id'] ?? 0,
                      jadwal['hari'] ?? '',
                      jadwal['kelas'] ?? '',
                    ),

                  if (_jadwalList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          "Tidak ada jadwal kelas untuk semester ini",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 70),
                ],
              ),

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFB71C1C),
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  // Tambahkan parameter tambahan dan onTap di _classCard
  // Dalam ClassPage, modifikasi _classCard:
  Widget _classCard(
    String title,
    String dosen, // ← Nama dosen untuk display
    String schedule,
    Color primaryRed,
    String ruangan,
    String jamMulai,
    String jamSelesai,
    int dosenId, // ← UBAH dari String ke int (parameter ke-8)
    int jadwalId,
    String hari,
    String kelas,
  ) {
    return GestureDetector(
      onTap: () {
        // DEBUG: Tampilkan data yang akan dikirim ke ClassDetail
        print('=== DEBUG: Data yang dikirim ke ClassDetail ===');
        print('Class Name: $title');
        print('Schedule: $schedule');
        print('Dosen: $dosen');
        print('Dosen ID: $dosenId'); // ← Sekarang ada dosenId yang benar
        print('Jadwal ID: $jadwalId');
        print('Hari: $hari');
        print('Ruangan: $ruangan');
        print('Kelas: $kelas');
        print('Jam Mulai: $jamMulai');
        print('Jam Selesai: $jamSelesai');
        print('============================================');

        // Navigasi ke ClassDetail dengan dosenId yang benar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ClassDetail(
                  className: title,
                  schedule: schedule,
                  dosenId: dosenId, // ← Sekarang pakai dosenId dari data
                  jadwalId: jadwalId,
                ),
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
            // Indicator merah di kiri
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),

            // Konten card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(dosen, style: const TextStyle(color: Colors.black54)), // ← Nama dosen
                  const SizedBox(height: 2),
                  Text(schedule, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),

            // Icon panah
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk extract dosenId dari nama dosen (sesuaikan dengan struktur data Anda)
  int _extractDosenId(String namaDosen) {
    // Contoh: jika namaDosen mengandung ID, atau Anda bisa mapping manual
    // Untuk sementara, return default value atau cari cara lain untuk mendapatkan dosenId
    print('⚠️ Perlu implementasi _extractDosenId untuk: $namaDosen');
    return 1; // Default value, sesuaikan dengan kebutuhan
  }

  // 🔹 Widget kartu kelas
  // Widget _classCard(
  //   String title,
  //   String lecturer,
  //   String info,
  //   Color bgColor,
  //   String ruangan,
  //   String jamMulai,
  //   String jamSelesai,
  // ) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
  //     child: ListTile(
  //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //       subtitle: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(lecturer, style: const TextStyle(color: Colors.white70)),
  //           const SizedBox(height: 4),
  //           Text("Ruangan: $ruangan", style: const TextStyle(color: Colors.white70)),
  //           Text("Jam: $jamMulai - $jamSelesai", style: const TextStyle(color: Colors.white70)),
  //         ],
  //       ),
  //       trailing: Text(info, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //     ),
  //   );
  // }
}
