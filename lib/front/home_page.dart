import 'dart:async';
import 'package:flutter/material.dart';
import 'course_detail_page.dart';
import '/back/jadwal_service.dart';
import '/back/login_sign_service.dart';
import '/back/tugas_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  int _selectedIndex = 0;

  late Future<List<Map<String, dynamic>>> futureMataKuliah;
  late Future<List<Map<String, dynamic>>> futureTugas;
  String userName = "LiA"; // default sementara sebelum fetch

  late DateTime _today;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    futureMataKuliah = JadwalService.fetchJadwal();
    futureTugas = TugasService.fetchTugas();
    _loadUserName();

    _today = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _today = DateTime.now();
      });
    });
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    if (name != null && mounted) {
      setState(() {
        userName = name;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatFullDate(DateTime dt) {
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
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
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/edit');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatFullDate(_today);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: primaryRed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "Notifikasi",
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // HEADER
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB71C1C),
                  Color(0xFFD32F2F),
                  Color(0xFFE57373),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, $userName!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(
                    'assets/profile.jpg',
                  ), // pastikan ada
                ),
              ],
            ),
          ),

          // KONTEN
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Mata Kuliah ---
                    const Text(
                      "Mata Kuliah",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureMataKuliah,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text("Belum ada jadwal mata kuliah"),
                              );
                            } else {
                              final mataKuliah = snapshot.data!;
                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: mataKuliah.length,
                                itemBuilder: (context, index) {
                                  final mk = mataKuliah[index];
                                  return _courseCard(
                                    context,
                                    mk['title'],
                                    mk['dosen'],
                                    mk['kelas'],
                                    mk['isRed'],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Tugas ---
                    const Text(
                      "Tugas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureTugas,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text("Belum ada tugas"),
                              );
                            } else {
                              final tugas = snapshot.data!;
                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: tugas.length,
                                itemBuilder: (context, index) {
                                  final t = tugas[index];
                                  final deadline = t['deadline']
                                      .toString()
                                      .split(" ")[0];
                                  return _taskCard(t['judul'], deadline, false);
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(
    BuildContext context,
    String title,
    String dosen,
    String kelas,
    bool isRed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? primaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(dosen, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          kelas,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CourseDetailPage(title: title, dosen: dosen, kelas: kelas),
            ),
          );
        },
      ),
    );
  }

  Widget _taskCard(String title, String date, bool isRed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? primaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          date,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
