import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../services/auth_service.dart';
import '../services/tugas_service.dart';

class AssignmentController with ChangeNotifier {
  final int tugasId;
  final String judul;
  final String deskripsi;
  final String deadline;
  final String fileUrl;
  final int jadwalId;
  final int dosenId;
  final String dosenNama;

  AssignmentModel _model = AssignmentModel();
  final Color primaryRed = const Color(0xFFB71C1C);

  AssignmentController({
    required this.tugasId,
    required this.judul,
    required this.deskripsi,
    required this.deadline,
    required this.fileUrl,
    required this.jadwalId,
    required this.dosenId,
    required this.dosenNama,
  }) {
    _initializeData();
  }

  AssignmentModel get model => _model;

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadAssignmentDetail();
  }

  Future<void> _loadUserData() async {
    try {
      final role = await AuthService.getUserRole();
      final userData = await AuthService.getCompleteUserProfile();

      _model = _model.copyWith(
        userRole: role ?? 'mahasiswa',
        userData: userData,
      );
      notifyListeners();
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadAssignmentDetail() async {
    try {
      _model = _model.copyWith(
        isLoading: true,
        errorMessage: '',
      );
      notifyListeners();

      // Load detail tugas
      final assignmentDetail = await TugasService.getTugasDetail(tugasId);

      // Load submission status untuk mahasiswa
      if (_model.isMahasiswa) {
        final submissionStatus = await TugasService.getSubmissionStatus(tugasId);

        _model = _model.copyWith(
          assignmentDetail: assignmentDetail,
          submissionStatus: submissionStatus,
          isLoading: false,
        );
      } else {
        _model = _model.copyWith(
          assignmentDetail: assignmentDetail,
          isLoading: false,
        );
      }

      notifyListeners();
      print("✅ Assignment detail loaded: ${_model.judul}");
    } catch (e) {
      _model = _model.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      notifyListeners();
      print("❌ Error loading assignment detail: $e");
    }
  }

  Future<void> submitAssignment(BuildContext context) async {
    if (!_model.canSubmit) return;

    // Simulasi upload file - dalam implementasi real, gunakan file picker
    final uploadedFileUrl = "https://example.com/uploaded_file.pdf";
    final fileName = "tugas_${tugasId}_${_model.userNim}.pdf";

    _model = _model.copyWith(isSubmitting: true);
    notifyListeners();

    try {
      final result = await TugasService.submitTugas(
        tugasId: tugasId,
        fileUrl: uploadedFileUrl,
        fileName: fileName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Tugas berhasil disubmit")),
      );

      // Reload submission status
      await _loadAssignmentDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal submit tugas: $e")),
      );
    } finally {
      _model = _model.copyWith(isSubmitting: false);
      notifyListeners();
    }
  }

  void showFileUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Pilih File'),
              onTap: () {
                Navigator.pop(context);
                // Implement file picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "Tanggal tidak tersedia";
    }

    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  String getFormattedDeadline() {
    final deadline = _model.assignmentDetail?['deadline'] ?? this.deadline;
    return deadline.toString().split(" ")[0];
  }

  void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  void retryLoading() {
    _loadAssignmentDetail();
  }
}