import 'package:flutter/material.dart';
import '../back/auth_service.dart';
import '../back/tugas_service.dart';
import '../back/postingan_service.dart'; // Pastikan Anda memiliki service untuk postingan

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
  
  // Variabel untuk fitur postingan dosen
  bool _showCreatePost = false;
  final TextEditingController _postTitleController = TextEditingController();
  final TextEditingController _postContentController = TextEditingController();
  bool _isCreatingPost = false;
  List<Map<String, dynamic>> _postinganList = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTugasDetail();
    _loadPostingan();
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

Future<void> _loadPostingan() async {
  try {
    print("🔄 START _loadPostingan - jadwalId: ${widget.jadwalId}");
    
    // Load daftar postingan untuk tugas/jadwal ini
    final List<Postingan> postingan = await PostinganService.getPostinganByJadwal(jadwalId: widget.jadwalId);
    
    print("📊 _loadPostingan - Received ${postingan.length} postingan");
    
    if (mounted) {
      setState(() {
        // Convert List<Postingan> to List<Map<String, dynamic>>
        _postinganList = postingan.map((post) {
          return {
            'id': post.id,
            'dosen_id': post.dosenId,
            'jadwal_id': post.jadwalId,
            'judul': post.judul,
            'konten': post.konten,
            'file_url': post.fileUrl,
            'created_at': post.createdAt?.toIso8601String(),
            'updated_at': post.updatedAt?.toIso8601String(),
            'dosen_nama': post.dosen?['nama'] ?? post.dosen?['name'] ?? 'Dosen',
          };
        }).toList();
        
        print("✅ _loadPostingan - Converted to ${_postinganList.length} maps");
      });
    }
  } catch (e) {
    print("❌ ERROR in _loadPostingan: $e");
    print("🔄 Setting empty list due to error");
    
    if (mounted) {
      setState(() {
        _postinganList = [];
      });
    }
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
      final result = await TugasService.submitTugas(
        tugasId: widget.tugasId,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Tugas berhasil disubmit"))
        );

        // Reload submission status
        await _loadTugasDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal submit tugas: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createPostingan() async {
    if (_userRole != 'dosen') return;

    final title = _postTitleController.text.trim();
    final content = _postContentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan konten postingan harus diisi"))
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      final result = await PostinganService.createPostingan(
        jadwalId: widget.jadwalId,
        judul: title,
        konten: content,
        dosenId: _userData?['dosen_id'] ?? widget.dosenId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Postingan berhasil dibuat"))
        );

        // Reset form
        _postTitleController.clear();
        _postContentController.clear();
        
        // Tutup form
        setState(() {
          _showCreatePost = false;
        });

        // Reload daftar postingan
        await _loadPostingan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuat postingan: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPost = false;
        });
      }
    }
  }

  void _showFileUploadOptions() {
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

  void _toggleCreatePost() {
    setState(() {
      _showCreatePost = !_showCreatePost;
      if (!_showCreatePost) {
        _postTitleController.clear();
        _postContentController.clear();
      }
    });
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
            if (submissionData['nilai'] != null)
              Text("Nilai: ${submissionData['nilai']}"),
            if (submissionData['komentar'] != null)
              Text("Komentar: ${submissionData['komentar']}"),
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

  Widget _buildCreatePostForm() {
    if (!_showCreatePost) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: primaryRed),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Buat Postingan Baru",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _postTitleController,
            decoration: const InputDecoration(
              labelText: "Judul Postingan",
              border: OutlineInputBorder(),
              hintText: "Masukkan judul postingan...",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postContentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Konten Postingan",
              border: OutlineInputBorder(),
              hintText: "Tulis konten postingan di sini...",
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _toggleCreatePost,
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isCreatingPost ? null : _createPostingan,
                  child: _isCreatingPost
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text("Buat Postingan"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostinganList() {
    if (_postinganList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(Icons.announcement, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              "Belum ada postingan",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              "Dosen dapat membuat postingan untuk memberikan informasi tambahan",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _postinganList.map((postingan) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryRed,
                  child: Text(
                    "D",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postingan['dosen_nama'] ?? 'Dosen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(postingan['created_at']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              postingan['judul'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(postingan['konten']),
          ],
        ),
      )).toList(),
    );
  }

  String _formatDate(String dateString) {
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
        actions: [
          // Tombol buat postingan hanya untuk dosen
          if (_userRole == 'dosen')
            IconButton(
              icon: Icon(
                _showCreatePost ? Icons.close : Icons.add_comment,
                color: primaryRed,
              ),
              onPressed: _toggleCreatePost,
              tooltip: _showCreatePost ? "Tutup Form" : "Buat Postingan",
            ),
        ],
      ),
      body: _isLoading
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
                        Text(
                          "Terjadi Kesalahan",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadTugasDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                          ),
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

                      // Form buat postingan (hanya untuk dosen)
                      if (_userRole == 'dosen') _buildCreatePostForm(),

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
                            const Text("100 points", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 12),
                            Text(
                              _tugasDetail?['deskripsi'] ?? widget.deskripsi,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),

                            // Informasi tambahan
                            Container(
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
                                  Text("Dosen: ${_tugasDetail?['dosenNama'] ?? widget.dosenNama}"),
                                  Text("Mata Kuliah: ${_tugasDetail?['mataKuliah'] ?? '-'}"),
                                  Text("Kelas: ${_tugasDetail?['kelas'] ?? '-'}"),
                                  Text("Prodi: ${_tugasDetail?['prodi'] ?? '-'}"),
                                  Text("Semester: ${_tugasDetail?['semester'] ?? '-'}"),
                                ],
                              ),
                            ),

                            // File terlampir
                            if (_tugasDetail?['fileUrl'] != null && _tugasDetail?['fileUrl'].isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text("File Terlampir:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(_tugasDetail!['fileUrl'], style: const TextStyle(fontSize: 14, color: Colors.blue)),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Postingan
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Row(
                          children: [
                            Icon(Icons.announcement, color: Colors.black54),
                            SizedBox(width: 8),
                            Text(
                              "Postingan Dosen",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPostinganList(),

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
                              child: _isSubmitting
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
                                        Text("Choose a File or Drag it here"),
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
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Submit Tugas", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _postTitleController.dispose();
    _postContentController.dispose();
    super.dispose();
  }
}