import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/class_controller.dart';
import '../services/auth_service.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ClassController(),
      child: Consumer<ClassController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                controller.model.greeting,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              actions: [Padding(padding: const EdgeInsets.only(right: 12), child: _buildProfileAvatar())],
            ),
            body: _buildBody(controller),
          );
        },
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
            radius: 18,
            backgroundColor: Colors.grey[300],
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          );
        }

        if (hasPhoto) {
          return CachedNetworkImage(
            imageUrl: photoUrl!,
            imageBuilder: (context, imageProvider) => CircleAvatar(radius: 18, backgroundImage: imageProvider),
            placeholder:
                (context, url) => CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
            errorWidget:
                (context, url, error) => CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFB71C1C),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
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
      radius: 18,
      backgroundColor: const Color(0xFFB71C1C),
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }

  Widget _buildBody(ClassController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.handleRefresh(),
      color: controller.primaryRed,
      backgroundColor: Colors.white,
      child: _buildContent(controller),
    );
  }

  Widget _buildContent(ClassController controller) {
    if (controller.model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.model.hasError) {
      return _buildErrorState(controller);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildHeader(controller),
        ..._buildJadwalList(controller),
        if (controller.model.isEmpty) _buildEmptyState(controller),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _buildHeader(ClassController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(controller.formatFullDate(controller.model.currentDate), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildJadwalList(ClassController controller) {
    return controller.model.jadwalList.map<Widget>((jadwal) {
      return _buildJadwalCard(controller, jadwal);
    }).toList();
  }

  Widget _buildJadwalCard(ClassController controller, Map<String, dynamic> jadwal) {
    final String title = jadwal['title'] ?? "Mata Kuliah";
    final String dosen = jadwal['dosen'] ?? "Dosen Tidak Diketahui";
    final String scheduleInfo = controller.getScheduleInfo(jadwal);

    return _classCard(
      controller: controller,
      title: title,
      dosen: dosen,
      scheduleInfo: scheduleInfo,
      ruangan: jadwal['ruangan'] ?? '-',
      jamMulai: jadwal['jamMulai'] ?? '-',
      jamSelesai: jadwal['jamSelesai'] ?? '-',
      jadwal: jadwal,
    );
  }

  Widget _buildErrorState(ClassController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.model.errorMessage!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.fetchJadwal(),
              style: ElevatedButton.styleFrom(backgroundColor: controller.primaryRed, foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ClassController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.model.emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _classCard({
    required ClassController controller,
    required String title,
    required String dosen,
    required String scheduleInfo,
    required String ruangan,
    required String jamMulai,
    required String jamSelesai,
    required Map<String, dynamic> jadwal,
  }) {
    return GestureDetector(
      onTap: () => controller.navigateToClassDetail(context, jadwal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border.all(color: controller.primaryRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(color: controller.primaryRed, borderRadius: BorderRadius.circular(2)),
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
                  Text(scheduleInfo, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
