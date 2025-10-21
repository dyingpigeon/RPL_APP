import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/assignment_controller.dart';

class AssignmentPage extends StatefulWidget {
  final int tugasId;
  final String judul;
  final String deskripsi;
  final String deadline;
  final String fileUrl;
  final int jadwalId;
  final int dosenId;
  final String dosenNama;

  const AssignmentPage({
    super.key,
    required this.tugasId,
    required this.judul,
    required this.deskripsi,
    required this.deadline,
    required this.fileUrl,
    required this.jadwalId,
    required this.dosenId,
    required this.dosenNama,
  });

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AssignmentController(
        tugasId: widget.tugasId,
        judul: widget.judul,
        deskripsi: widget.deskripsi,
        deadline: widget.deadline,
        fileUrl: widget.fileUrl,
        jadwalId: widget.jadwalId,
        dosenId: widget.dosenId,
        dosenNama: widget.dosenNama,
      ),
      child: Consumer<AssignmentController>(
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
                controller.model.judul.isNotEmpty ? controller.model.judul : widget.judul,
                style: const TextStyle(color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(AssignmentController controller) {
    if (controller.model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.model.hasError) {
      return _buildErrorState(controller);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(controller),
          if (controller.model.isMahasiswa) _buildSubmissionStatus(controller),
          _buildAssignmentDetail(controller),
          _buildActionSection(controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(AssignmentController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Terjadi Kesalahan",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              controller.model.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.retryLoading(),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AssignmentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: controller.primaryRed,
            child: Text(
              controller.model.isMahasiswa ? 'M' : 'D',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.model.userName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildUserInfo(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AssignmentController controller) {
    if (controller.model.isMahasiswa) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NIM: ${controller.model.userNim}", style: const TextStyle(fontSize: 14)),
          Text("Kelas: ${controller.model.userKelas}", style: const TextStyle(fontSize: 14)),
          Text("Prodi: ${controller.model.userProdi}", style: const TextStyle(fontSize: 14)),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NIP: ${controller.model.userNip}", style: const TextStyle(fontSize: 14)),
          Text("Sebagai: Dosen Pengajar", style: const TextStyle(fontSize: 14)),
        ],
      );
    }
  }

  Widget _buildSubmissionStatus(AssignmentController controller) {
    final isSubmitted = controller.model.isSubmitted;
    final submissionData = controller.model.submissionStatus?['submissionData'];

    if (isSubmitted && submissionData != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("Tugas Telah Disubmit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Text("File: ${submissionData['fileUrl'] ?? '-'}"),
            if (submissionData['nilai'] != null) Text("Nilai: ${submissionData['nilai']}"),
            if (submissionData['komentar'] != null) Text("Komentar: ${submissionData['komentar']}"),
            if (submissionData['submittedAt'] != null)
              Text("Waktu Submit: ${controller.formatDate(submissionData['submittedAt'])}"),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Belum Submit Tugas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
      );
    }
  }

  Widget _buildAssignmentDetail(AssignmentController controller) {
    final formattedDeadline = controller.getFormattedDeadline();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: controller.primaryRed, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.model.judul,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Deadline: $formattedDeadline",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "100 points",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            controller.model.deskripsi,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildAdditionalInfo(controller),
          _buildFileAttachment(controller),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(AssignmentController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Informasi Tugas:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Dosen: ${controller.model.dosenNama}"),
          Text("Mata Kuliah: ${controller.model.mataKuliah}"),
          Text("Kelas: ${controller.model.kelas}"),
          Text("Prodi: ${controller.model.prodi}"),
          Text("Semester: ${controller.model.semester}"),
        ],
      ),
    );
  }

  Widget _buildFileAttachment(AssignmentController controller) {
    if (controller.model.fileUrl == null || controller.model.fileUrl!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        const Text("File Terlampir:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(controller.model.fileUrl!, style: const TextStyle(fontSize: 14, color: Colors.blue)),
      ],
    );
  }

  Widget _buildActionSection(AssignmentController controller) {
    return Column(
      children: [
        if (controller.model.canSubmit) ...[
          _buildFileUploadSection(controller),
          _buildSubmitButton(controller),
        ],
        if (controller.model.isDosen) _buildDosenInfo(controller),
      ],
    );
  }

  Widget _buildFileUploadSection(AssignmentController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GestureDetector(
        onTap: controller.model.isSubmitting ? null : () => controller.showFileUploadOptions(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: controller.model.isSubmitting ? Colors.grey : Colors.black26),
            borderRadius: BorderRadius.circular(8),
            color: controller.model.isSubmitting ? Colors.grey[100] : Colors.white,
          ),
          child: controller.model.isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 8),
                    Text("Mengupload..."),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: Colors.black54),
                    SizedBox(width: 8),
                    Text("Pilih File untuk Diupload"),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AssignmentController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.primaryRed,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: controller.model.isSubmitting ? null : () => controller.submitAssignment(context),
        child: controller.model.isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Submit Tugas", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildDosenInfo(AssignmentController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text("Info Dosen", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Anda dapat melihat detail tugas dan submission mahasiswa di halaman ini.",
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}