import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/class_detail_controller.dart';
import '../services/postingan_service.dart';

class ClassDetail extends StatefulWidget {
  final String className;
  final String schedule;
  final int dosenId;
  final int jadwalId;

  const ClassDetail({
    super.key,
    required this.className,
    required this.schedule,
    required this.dosenId,
    required this.jadwalId,
  });

  @override
  State<ClassDetail> createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetail> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => ClassDetailController(
            className: widget.className,
            schedule: widget.schedule,
            dosenId: widget.dosenId,
            jadwalId: widget.jadwalId,
          ),
      child: Consumer<ClassDetailController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => controller.navigateBack(context),
              ),
              title: Text(
                widget.className,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: () => controller.refreshData(),
                  tooltip: 'Refresh',
                ),
                if (controller.model.canCreatePostingan)
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: () => controller.createPostingan(context),
                    tooltip: 'Buat Pengumuman',
                  ),
              ],
            ),
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(ClassDetailController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassHeader(controller),
            const SizedBox(height: 20),
            _buildAnnouncementsSection(controller),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClassHeader(ClassDetailController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: controller.primaryRed, borderRadius: BorderRadius.circular(25)),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.className,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(widget.schedule, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(controller.model.dosenInfo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (controller.model.isDosen) ...[
                  const SizedBox(height: 2),
                  Text('ID Dosen: ${widget.dosenId}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(ClassDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(controller.model.sectionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (controller.model.postinganList.isNotEmpty)
              Text(
                '${controller.model.postinganList.length} postingan',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContent(controller),
      ],
    );
  }

  Widget _buildContent(ClassDetailController controller) {
    if (controller.model.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.model.hasError) {
      return _buildErrorState(controller);
    }

    if (controller.model.isEmpty) {
      return _buildEmptyState(controller);
    }

    return Column(
      children:
          controller.model.postinganList.map((postingan) {
            return _buildAnnouncementItem(controller: controller, postingan: postingan);
          }).toList(),
    );
  }

  Widget _buildErrorState(ClassDetailController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            controller.model.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ClassDetailController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.announcement_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            controller.model.emptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            controller.model.emptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          if (controller.model.canCreatePostingan) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.createPostingan(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Buat Pengumuman Pertama', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem({required ClassDetailController controller, required Postingan postingan}) {
    final date = controller.formatDate(postingan);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: controller.primaryRed.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: controller.primaryRed, borderRadius: BorderRadius.circular(18)),
                child: Icon(controller.model.isDosen ? Icons.person : Icons.school, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.model.namaDosen, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (controller.model.canDeletePostingan)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => controller.deletePostingan(context, postingan.id, postingan.judul),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus Pengumuman',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(
            postingan.judul,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(postingan.konten, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
          if (postingan.fileUrl != null && postingan.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      postingan.fileUrl!,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('Diposting $date', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const Spacer(),
              if (controller.model.isDosen)
                Text(
                  'Anda yang memposting',
                  style: TextStyle(color: controller.primaryRed, fontSize: 11, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
