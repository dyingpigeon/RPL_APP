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

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    fetchJadwal();
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
        title: const Text("Hi, LiA!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  for (var jadwal in _jadwalList)
                    _classCard(
                      jadwal['title'] ?? "Mata Kuliah",
                      "Dosen: ${jadwal['dosen']}",
                      "Kelas ${jadwal['kelas']} | ${jadwal['hari'].toString().toUpperCase()}",
                      primaryRed,
                      jadwal['ruangan'] ?? '-',
                      jadwal['jamMulai'] ?? '-',
                      jadwal['jamSelesai'] ?? '-',
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

  // 🔹 Widget kartu kelas
  Widget _classCard(
    String title,
    String lecturer,
    String info,
    Color bgColor,
    String ruangan,
    String jamMulai,
    String jamSelesai,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lecturer, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text("Ruangan: $ruangan", style: const TextStyle(color: Colors.white70)),
            Text("Jam: $jamMulai - $jamSelesai", style: const TextStyle(color: Colors.white70)),
          ],
        ),
        trailing: Text(info, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
