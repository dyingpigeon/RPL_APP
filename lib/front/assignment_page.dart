import 'package:flutter/material.dart';
import '../back/auth_service.dart';
import '../back/tugas_service.dart';

class CourseDetailPage extends StatefulWidget {
  final int tugasId;
  final String judul;
  final String deskripsi;
  final String deadline;
  final String fileUrl;
  final int jadwalId;
  final int dosenId;
  final String dosenNama;

  const CourseDetailPage({
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
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  Map<String, dynamic>? _tugasDetail;
  Map<String, dynamic>? _submissionStatus;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  String _userRole = 'mahasiswa';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTugasDetail();
  }

  Future<void> _loadUserData() async {
    try {
      final role = await AuthService.getUserRole();
      final userData = await AuthService.getCompleteUserProfile();

      if (mounted) {
        setState(() {
          _userRole = role ?? 'mahasiswa';
          _userData = userData;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadTugasDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load detail tugas
      final tugasDetail = await TugasService.getTugasDetail(widget.tugasId);

      // Load submission status untuk mahasiswa
      if (_userRole == 'mahasiswa') {
        final submissionStatus = await TugasService.getSubmissionStatus(widget.tugasId);

        if (mounted) {
          setState(() {
            _tugasDetail = tugasDetail;
            _submissionStatus = submissionStatus;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _tugasDetail = tugasDetail;
            _isLoading = false;
          });
        }
      }

      print("✅ Tugas detail loaded: ${_tugasDetail?['judul']}");
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      print("❌ Error loading tugas detail: $e");
    }
  }

  Future<void> _submitTugas() async {
    if (_userRole != 'mahasiswa') return;

    // Simulasi upload file - dalam implementasi real, gunakan file picker
    final fileUrl = "https://example.com/uploaded_file.pdf";
    final fileName = "tugas_${widget.tugasId}_${_userData?['nim'] ?? 'unknown'}.pdf";

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await TugasService.submitTugas(tugasId: widget.tugasId, fileUrl: fileUrl, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? "Tugas berhasil disubmit")));

        // Reload submission status
        await _loadTugasDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal submit tugas: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showFileUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
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

  Widget _buildUserInfo() {
    if (_userRole == 'mahasiswa') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NIM: ${_userData?['nim'] ?? '-'}", style: const TextStyle(fontSize: 14)),
          Text("Kelas: ${_userData?['kelas'] ?? '-'}", style: const TextStyle(fontSize: 14)),
          Text("Prodi: ${_userData?['prodi'] ?? '-'}", style: const TextStyle(fontSize: 14)),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NIP: ${_userData?['nip'] ?? '-'}", style: const TextStyle(fontSize: 14)),
          Text("Sebagai: Dosen Pengajar", style: const TextStyle(fontSize: 14)),
        ],
      );
    }
  }

  Widget _buildSubmissionStatus() {
    if (_userRole != 'mahasiswa') return const SizedBox();

    final isSubmitted = _submissionStatus?['submitted'] ?? false;
    final submissionData = _submissionStatus?['submissionData'];

    if (isSubmitted && submissionData != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
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
              Text("Waktu Submit: ${_formatDate(submissionData['submittedAt'])}"),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
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

  String _formatDate(String? dateString) {
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

  @override
  Widget build(BuildContext context) {
    final deadline = _tugasDetail?['deadline'] ?? widget.deadline;
    final formattedDeadline = deadline.toString().split(" ")[0];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tugasDetail?['judul'] ?? widget.judul,
          style: const TextStyle(color: Colors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Terjadi Kesalahan", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadTugasDetail,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan informasi user
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: primaryRed,
                            child: Text(
                              _userRole == 'mahasiswa' ? 'M' : 'D',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData?['name'] ?? 'User',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                _buildUserInfo(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status submission (untuk mahasiswa)
                    if (_userRole == 'mahasiswa') _buildSubmissionStatus(),

                    // Container detail tugas
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryRed, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tugasDetail?['judul'] ?? widget.judul,
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
                            _tugasDetail?['deskripsi'] ?? widget.deskripsi,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),

                          // Informasi tambahan
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Informasi Tugas:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Dosen: ${_tugasDetail?['dosenNama'] ?? widget.dosenNama}"),
                                Text("Mata Kuliah: ${_tugasDetail?['mataKuliah'] ?? '-'}"),
                                Text("Kelas: ${_tugasDetail?['kelas'] ?? '-'}"),
                                Text("Prodi: ${_tugasDetail?['prodi'] ?? '-'}"),
                                Text("Semester: ${_tugasDetail?['semester'] ?? '-'}"),
                              ],
                            ),
                          ),

                          // File terlampir
                          if (_tugasDetail?['fileUrl'] != null && (_tugasDetail?['fileUrl'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text("File Terlampir:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(_tugasDetail!['fileUrl'], style: const TextStyle(fontSize: 14, color: Colors.blue)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // File upload section (hanya untuk mahasiswa yang belum submit)
                    if (_userRole == 'mahasiswa' && !(_submissionStatus?['submitted'] ?? false))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _showFileUploadOptions,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: _isSubmitting ? Colors.grey : Colors.black26),
                              borderRadius: BorderRadius.circular(8),
                              color: _isSubmitting ? Colors.grey[100] : Colors.white,
                            ),
                            child:
                                _isSubmitting
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
                      ),

                    // Tombol submit (hanya untuk mahasiswa yang belum submit)
                    if (_userRole == 'mahasiswa' && !(_submissionStatus?['submitted'] ?? false)) ...[
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isSubmitting ? null : _submitTugas,
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Submit Tugas", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],

                    // Info untuk dosen
                    if (_userRole == 'dosen') ...[
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
