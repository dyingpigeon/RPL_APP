import 'dart:async';
import 'package:elearning_rpl_5d/front/assignment_page.dart';
import 'package:flutter/material.dart';
import 'class_detail_page.dart';
import '/back/jadwal_service.dart';
import '../back/auth_service.dart';
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
  String userName = "Mahasiswa"; // default sebelum fetch

  late DateTime _today;
  late Timer _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _today = DateTime.now();
      });
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserName();
    await _loadJadwalAndTugas();
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

  Future<void> _loadJadwalAndTugas() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Pastikan user sudah login dan memiliki data mahasiswa
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        print("User belum login");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final hasMahasiswaData = await AuthService.hasMahasiswaData();
      if (!hasMahasiswaData) {
        print("Data mahasiswa tidak tersedia");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Load data jadwal dan tugas
      if (mounted) {
        setState(() {
          futureMataKuliah = JadwalService.fetchJadwal();
          futureTugas = TugasService.fetchTugas();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading jadwal and tugas: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadJadwalAndTugas();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/class');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatFullDate(_today);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: primaryRed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // HEADER
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE57373)],
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
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(formattedDate, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: AuthService.getMahasiswa(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final mahasiswa = snapshot.data!;
                              final kelas = mahasiswa['kelas'] ?? '';
                              final prodi = mahasiswa['prodi'] ?? '';
                              if (kelas.isNotEmpty && prodi.isNotEmpty) {
                                return Text(
                                  '$prodi - $kelas',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                );
                              }
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(radius: 28, backgroundImage: AssetImage('assets/profile.jpg')),
                ],
              ),
            ),

            // KONTEN
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                      else
                        ..._buildContent(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      // --- Mata Kuliah ---
      const Text("Mata Kuliah Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 200,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureMataKuliah,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Error: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                        child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Tidak ada jadwal mata kuliah\nhari ini",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final mataKuliah = snapshot.data!;

                // DEBUG: Tampilkan semua data yang diterima dari JadwalService
                print('=== DEBUG: Data dari JadwalService ===');
                for (var i = 0; i < mataKuliah.length; i++) {
                  final mk = mataKuliah[i];
                  print('Item $i:');
                  print('  - id: ${mk['id']}');
                  print('  - title: ${mk['title']}');
                  print('  - dosen: ${mk['dosen']}');
                  print('  - kelas: ${mk['kelas']}');
                  print('  - hari: ${mk['hari']}');
                  print('  - jamMulai: ${mk['jamMulai']}');
                  print('  - jamSelesai: ${mk['jamSelesai']}');
                  print('  - ruangan: ${mk['ruangan']}');
                  print('  - semester: ${mk['semester']}');
                  print('  - prodi: ${mk['prodi']}');
                  print('  - matkulId: ${mk['matkulId']}');
                  print('  ---');
                }
                print('===================================');

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: mataKuliah.length,
                  itemBuilder: (context, index) {
                    final mk = mataKuliah[index];
                    return _courseCard(
                      // context,
                      mk['id'] ?? 0, // ID jadwal dari database
                      mk['title'] ?? 'Mata Kuliah',
                      mk['dosenId'] ?? 'Dosen', // Ini masih string, perlu di-extract
                      mk['kelas'] ?? 'Kelas',
                      mk['isRed'] ?? false,
                      hari: mk['hari'] ?? '',
                      jamMulai: mk['jamMulai'] ?? '',
                      jamSelesai: mk['jamSelesai'] ?? '',
                      ruangan: mk['ruangan'] ?? '',
                    );
                  },
                );
              }
            },
          ),
        ),
      ),

      const SizedBox(height: 24),

      const SizedBox(height: 24),

      // --- Tugas ---
      const SizedBox(height: 24),

      // --- Tugas ---
      const Text("Tugas Terdekat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 200,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureTugas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  // ← GUNAKAN CENTER
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Error: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                        child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  // ← GUNAKAN CENTER
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Tidak ada tugas terdekat",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final tugas = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tugas.length,
                  itemBuilder: (context, index) {
                    final t = tugas[index];
                    final deadline = t['deadline']?.toString().split(" ")[0] ?? '-';
                    return _taskCard(
                      t['judul'] ?? 'Tugas', // Parameter 1: judul
                      deadline, // Parameter 2: deadline
                      t['isRed'] ?? false, // Parameter 3: isRed
                      t['deskripsi'] ?? '', // Parameter 4: deskripsi (BARU)
                      t['jadwalId'] ?? 0, // Parameter 5: jadwalId (BARU)
                      t['fileUrl'] ?? '', // Parameter 6: fileUrl (BARU)
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    ];
  }

  Widget _courseCard(
    // BuildContext context,
    int jadwal,
    String title,
    int dosen,
    String kelas,
    bool isRed, {
    String hari = '',
    String jamMulai = '',
    String jamSelesai = '',
    String ruangan = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? primaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(dosen, style: const TextStyle(color: Colors.white70)),
            if (hari.isNotEmpty && jamMulai.isNotEmpty)
              Text('$hari, $jamMulai-$jamSelesai', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (ruangan.isNotEmpty)
              Text('Ruangan: $ruangan', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        trailing: Text(kelas, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onTap: () {
          // DEBUG: Tampilkan data yang akan dikirim ke ClassDetail
          print('=== DEBUG: Data yang dikirim ke ClassDetail ===');
          print('Class Name: $title');
          print('Schedule: $jamMulai - $jamSelesai');
          print('Dosen: $dosen');
          // print('Dosen ID (extracted): $dosen');
          // print('Jadwal ID (generated): $jadwalId');
          print('Hari: $hari');
          print('Ruangan: $ruangan');
          print('Kelas: $kelas');
          print('============================================');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ClassDetail(
                    className: title,
                    schedule: '$jamMulai - $jamSelesai',
                    dosenId: dosen,
                    jadwalId: jadwal,
                  ),
            ),
          );
        },
      ),
    );
  }

  // Helper function untuk extract dosenId dari string dosen
  // int _extractDosenId(String dosen) {
  //   try {
  //     // Coba extract ID dari format: "Nama Dosen (ID)"
  //     final regex = RegExp(r'\((\d+)\)');
  //     final match = regex.firstMatch(dosen);
  //     if (match != null) {
  //       return int.parse(match.group(1)!);
  //     }

  //     // Jika tidak ada format ID, gunakan hash dari string sebagai fallback
  //     return dosen.hashCode.abs();
  //   } catch (e) {
  //     // Fallback ke nilai default jika terjadi error
  //     return 1;
  //   }
  // }

  // Helper function untuk extract jadwalId
  // int _extractJadwalId(String title, String jamMulai, String jamSelesai) {
  //   try {
  //     // Generate unique ID berdasarkan kombinasi title dan jam
  //     final uniqueString = '$title$jamMulai$jamSelesai';
  //     return uniqueString.hashCode.abs();
  //   } catch (e) {
  //     return 1; // Fallback value
  //   }
  // }

  // int _extractJadwalId(String dosen) {
  //   try {
  //     // Coba extract ID dari format: "Nama Dosen (ID)"
  //     final regex = RegExp(r'\((\d+)\)');
  //     final match = regex.firstMatch(dosen);
  //     if (match != null) {
  //       return int.parse(match.group(1)!);
  //     }

  //     // Jika tidak ada format ID, gunakan hash dari string sebagai fallback
  //     return dosen.hashCode.abs();
  //   } catch (e) {
  //     // Fallback ke nilai default jika terjadi error
  //     return 1;
  //   }
  // }

  Widget _taskCard(String judul, String deadline, bool isRed, String deskripsi, int jadwalId, String fileUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? primaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(judul, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Deadline", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(deadline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CourseDetailPage(
                    judul: judul,
                    jadwalId: jadwalId,
                    deskripsi: deskripsi,
                    deadline: deadline,
                    fileUrl: fileUrl,
                  ),
            ),
          );
          // ← TAMBAHKAN INI
          // Action ketika tugas ditekan
          print('Tugas ditekan: $judul');
          // Bisa navigasi ke halaman detail tugas
        },
      ),
    );
  }
}
