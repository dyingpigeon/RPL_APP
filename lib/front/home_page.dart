import 'dart:async';
import 'package:elearning_rpl_5d/front/course_detail_page.dart';
import 'package:flutter/material.dart';
import 'class_detail_page.dart';
import '/back/jadwal_service.dart';
import '../back/auth_service.dart';
import '/back/tugas_service.dart';

const Color primaryRed = Color(0xFFC2000E);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late Future<List<Map<String, dynamic>>> futureMataKuliah;
  late Future<List<Map<String, dynamic>>> futureTugas;
  String userName = "User";
  String userRole = "mahasiswa";

  late DateTime _today;
  late Timer _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _today = DateTime.now();
        });
      }
    });
    _initializeData();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await AuthService.getUserRole();
      if (role != null && mounted) {
        setState(() {
          userRole = role;
        });
      }
    } catch (e) {
      print("Error loading user role: $e");
    }
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

      final role = await AuthService.getUserRole();
      
      futureMataKuliah = JadwalService.fetchJadwal();
      futureTugas = TugasService.fetchTugas();

      if (mounted) {
        setState(() {
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
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    String dayName = days[dt.weekday % 7];
    String monthName = months[dt.month - 1];
    return "$dayName, ${dt.day} $monthName ${dt.year}";
  }

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  //   if (index == 0) {
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } else if (index == 1) {
  //     Navigator.pushReplacementNamed(context, '/class');
  //   } else if (index == 2) {
  //     Navigator.pushReplacementNamed(context, '/edit');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatFullDate(_today);

    return Scaffold(
      backgroundColor: Colors.white,
      // bottomNavigationBar: ClipRRect(
      //   borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      //   child: BottomNavigationBar(
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //     selectedItemColor: Colors.white,
      //     unselectedItemColor: Colors.white70,
      //     backgroundColor: primaryRed,
      //     items: const [
      //       BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //       BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
      //       BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      //     ],
      //   ),
      // ),
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
                          userRole == 'mahasiswa' ? 'Hi, $userName!' : 'Selamat Mengajar, $userName!',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(formattedDate, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        if (userRole == 'mahasiswa')
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
                          )
                        else if (userRole == 'dosen')
                          FutureBuilder<Map<String, dynamic>>(
                            future: AuthService.getDosen(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final dosen = snapshot.data!;
                                final nama = dosen['nama'] ?? '';
                                if (nama.isNotEmpty) {
                                  return Text(
                                    'Dosen $nama',
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  );
                                }
                              }
                              return const Text('Dosen', style: TextStyle(color: Colors.white70, fontSize: 14));
                            },
                          ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 28, 
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        ..._buildContentByRole(),
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

  List<Widget> _buildContentByRole() {
    if (userRole == 'mahasiswa') {
      return [
        const Text("Jadwal Kelas Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.school_outlined,
                    message: "Tidak ada jadwal mata kuliah\nhari ini",
                  );
                } else {
                  final mataKuliah = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: mataKuliah.length,
                    itemBuilder: (context, index) {
                      final mk = mataKuliah[index];
                      return _courseCard(
                        jadwalId: mk['id'] ?? 0,
                        title: mk['title'] ?? 'Mata Kuliah',
                        dosenId: mk['dosenId'] ?? 0,
                        kelas: mk['kelas'] ?? 'Kelas',
                        isRed: mk['isRed'] ?? false,
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
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.assignment_outlined,
                    message: "Tidak ada tugas terdekat",
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
                        tugasId: t['id'] ?? 0,
                        judul: t['judul'] ?? 'Tugas',
                        deadline: deadline,
                        isRed: t['isRed'] ?? false,
                        deskripsi: t['deskripsi'] ?? '',
                        jadwalId: t['jadwalId'] ?? 0,
                        fileUrl: t['fileUrl'] ?? '',
                        dosenId: t['dosenId'] ?? 0,
                        dosenNama: t['dosenNama'] ?? 'Dosen',
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ];
    } else if (userRole == 'dosen') {
      return [
        const Text("Jadwal Mengajar Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.school_outlined,
                    message: "Tidak ada jadwal mengajar hari ini",
                  );
                } else {
                  final jadwal = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: jadwal.length,
                    itemBuilder: (context, index) {
                      final j = jadwal[index];
                      return _courseCard(
                        jadwalId: j['id'] ?? 0,
                        title: j['title'] ?? 'Mata Kuliah',
                        dosenId: j['dosenId'] ?? 0,
                        kelas: j['kelas'] ?? 'Kelas',
                        isRed: j['isRed'] ?? false,
                        hari: j['hari'] ?? '',
                        jamMulai: j['jamMulai'] ?? '',
                        jamSelesai: j['jamSelesai'] ?? '',
                        ruangan: j['ruangan'] ?? '',
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        const Text("Tugas yang Dibuat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.assignment_outlined,
                    message: "Tidak ada tugas yang dibuat",
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
                        tugasId: t['id'] ?? 0,
                        judul: t['judul'] ?? 'Tugas',
                        deadline: deadline,
                        isRed: t['isRed'] ?? false,
                        deskripsi: t['deskripsi'] ?? '',
                        jadwalId: t['jadwalId'] ?? 0,
                        fileUrl: t['fileUrl'] ?? '',
                        dosenId: t['dosenId'] ?? 0,
                        dosenNama: t['dosenNama'] ?? 'Dosen',
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ];
    } else {
      return [
        _buildEmptyState(
          icon: Icons.error_outline,
          message: "Role tidak dikenali",
        ),
      ];
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error.length > 100 ? '${error.substring(0, 100)}...' : error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _courseCard({
  required int jadwalId,
  required String title,
  required int dosenId,
  required String kelas,
  required bool isRed,
  String hari = '',
  String jamMulai = '',
  String jamSelesai = '',
  String ruangan = '',
}) {
  final localPrimaryRed = primaryRed;
  return Builder(
    builder: (ctx) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? localPrimaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hari.isNotEmpty && jamMulai.isNotEmpty)
              Text(
                '$hari, $jamMulai-$jamSelesai', 
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            if (ruangan.isNotEmpty)
              Text(
                'Ruangan: $ruangan', 
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          kelas, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          print('=== DEBUG: Data yang dikirim ke ClassDetail ===');
          print('Class Name: $title');
          print('Jadwal ID: $jadwalId');
          print('Dosen ID: $dosenId');
          print('Hari: $hari');
          print('Jam: $jamMulai - $jamSelesai');
          print('Ruangan: $ruangan');
          print('Kelas: $kelas');
          print('============================================');

          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (context) => ClassDetail(
                className: title,
                schedule: '$hari, $jamMulai-$jamSelesai',
                dosenId: dosenId,
                jadwalId: jadwalId,
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _taskCard({
  required String judul,
  required String deadline,
  required bool isRed,
  required String deskripsi,
  required int jadwalId,
  required String fileUrl,
  required int tugasId,
  required int dosenId,
  required String dosenNama,
}) {
  final localPrimaryRed = primaryRed;
  return Builder(
    builder: (ctx) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRed ? localPrimaryRed : const Color(0xFFF4C1C1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          judul, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          deskripsi.isNotEmpty && deskripsi.length > 50 
            ? '${deskripsi.substring(0, 50)}...' 
            : deskripsi,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Deadline", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              deadline, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(
                tugasId: tugasId,
                judul: judul,
                deskripsi: deskripsi,
                deadline: deadline,
                fileUrl: fileUrl,
                jadwalId: jadwalId,
                dosenId: dosenId,
                dosenNama: dosenNama,
              ),
            ),
          );
          print('Tugas ditekan: $judul');
        },
      ),
    ),
  );
}