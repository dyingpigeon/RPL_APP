import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/home_controller.dart';
import 'class_detail_page.dart';
import 'assignment_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<HomeController>(
          builder: (context, controller, child) {
            return RefreshIndicator(
              onRefresh: () => controller.refreshData(),
              child: Column(
                children: [
                  // HEADER SECTION
                  _buildHeaderSection(controller),

                  // CONTENT SECTION
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
                        child: _buildContentSection(controller),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(HomeController controller) {
    final formattedDate = controller.formatFullDate(controller.model.currentDate);

    return Container(
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
                  controller.getGreeting(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                _buildUserInfo(controller),
              ],
            ),
          ),
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return FutureBuilder<String?>(
      future: AuthService.getUserPhotoUrl(),
      builder: (context, snapshot) {
        final String? photoUrl = snapshot.data;
        final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (hasPhoto) {
          return CachedNetworkImage(
            imageUrl: photoUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(radius: 28, backgroundImage: imageProvider),
            placeholder:
                (context, url) => CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            errorWidget:
                (context, url, error) => CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.person, size: 32, color: Colors.white),
                ),
          );
        } else {
          return _buildDefaultAvatar();
        }
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: const Icon(Icons.person, size: 32, color: Colors.white),
    );
  }

  Widget _buildUserInfo(HomeController controller) {
    if (controller.model.userRole == 'mahasiswa') {
      return FutureBuilder<Map<String, dynamic>>(
        future: AuthService.getMahasiswa(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final mahasiswa = snapshot.data!;
            final kelas = mahasiswa['kelas'] ?? '';
            final prodi = mahasiswa['prodi'] ?? '';
            if (kelas.isNotEmpty && prodi.isNotEmpty) {
              return Text('$prodi - $kelas', style: const TextStyle(color: Colors.white70, fontSize: 14));
            }
          }
          return const SizedBox();
        },
      );
    } else if (controller.model.userRole == 'dosen') {
      return FutureBuilder<Map<String, dynamic>>(
        future: AuthService.getDosen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final dosen = snapshot.data!;
            final nama = dosen['nama'] ?? '';
            if (nama.isNotEmpty) {
              return Text('Dosen $nama', style: const TextStyle(color: Colors.white70, fontSize: 14));
            }
          }
          return const Text('Dosen', style: TextStyle(color: Colors.white70, fontSize: 14));
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildContentSection(HomeController controller) {
    if (controller.model.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.model.userRole == 'mahasiswa') ..._buildMahasiswaContent(controller),
        if (controller.model.userRole == 'dosen') ..._buildDosenContent(controller),
        if (controller.model.userRole != 'mahasiswa' && controller.model.userRole != 'dosen')
          _buildEmptyState(icon: Icons.error_outline, message: "Role tidak dikenali"),
      ],
    );
  }

  List<Widget> _buildMahasiswaContent(HomeController controller) {
    return [
      _buildSectionTitle("Jadwal Kelas Hari Ini"),
      const SizedBox(height: 8),
      _buildJadwalSection(controller, "Tidak ada jadwal mata kuliah\nhari ini"),
      const SizedBox(height: 24),
      _buildSectionTitle("Tugas Terdekat"),
      const SizedBox(height: 8),
      _buildTugasSection(controller, "Tidak ada tugas terdekat"),
    ];
  }

  List<Widget> _buildDosenContent(HomeController controller) {
    return [
      _buildSectionTitle("Jadwal Mengajar Hari Ini"),
      const SizedBox(height: 8),
      _buildJadwalSection(controller, "Tidak ada jadwal mengajar hari ini"),
      const SizedBox(height: 24),
      _buildSectionTitle("Tugas yang Dibuat"),
      const SizedBox(height: 8),
      _buildTugasSection(controller, "Tidak ada tugas yang dibuat"),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildJadwalSection(HomeController controller, String emptyMessage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(height: 200, child: _buildJadwalList(controller, emptyMessage)),
    );
  }

  Widget _buildJadwalList(HomeController controller, String emptyMessage) {
    if (!controller.model.hasMataKuliah) {
      return _buildEmptyState(icon: Icons.school_outlined, message: emptyMessage);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.model.mataKuliah.length,
      itemBuilder: (context, index) {
        final mk = controller.model.mataKuliah[index];
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

  Widget _buildTugasSection(HomeController controller, String emptyMessage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(height: 200, child: _buildTugasList(controller, emptyMessage)),
    );
  }

  Widget _buildTugasList(HomeController controller, String emptyMessage) {
    if (!controller.model.hasTugas) {
      return _buildEmptyState(icon: Icons.assignment_outlined, message: emptyMessage);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.model.tugas.length,
      itemBuilder: (context, index) {
        final t = controller.model.tugas[index];
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

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
  const primaryRed = Color(0xFFC2000E);

  return Builder(
    builder:
        (ctx) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isRed ? primaryRed : const Color(0xFFF4C1C1),
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
                  Text('$hari, $jamMulai-$jamSelesai', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (ruangan.isNotEmpty)
                  Text('Ruangan: $ruangan', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            trailing: Text(kelas, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  builder:
                      (context) => ClassDetail(
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
  const primaryRed = Color(0xFFC2000E);

  return Builder(
    builder:
        (ctx) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isRed ? primaryRed : const Color(0xFFF4C1C1),
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
              deskripsi.isNotEmpty && deskripsi.length > 50 ? '${deskripsi.substring(0, 50)}...' : deskripsi,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Deadline", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(deadline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            onTap: () {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder:
                      (context) => AssignmentPage(
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
