import 'package:flutter/material.dart';
import 'package:elearning_rpl_5d/back/postingan_service.dart';
import 'package:elearning_rpl_5d/back/dosen_service.dart';
import 'package:elearning_rpl_5d/back/auth_service.dart';

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
  List<Postingan> _postinganList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _namaDosen = '';
  String _userRole = 'mahasiswa'; // default
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPostingan();
    _loadNamaDosen();
  }

  // METHOD BARU: Load data user
  Future<void> _loadUserData() async {
    try {
      final role = await AuthService.getUserRole();
      final name = await AuthService.getUserName();
      
      if (mounted) {
        setState(() {
          _userRole = role ?? 'mahasiswa';
          _userName = name ?? 'User';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadPostingan() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final postingan = await PostinganService.getPostingan(
        dosenId: widget.dosenId, 
        jadwalId: widget.jadwalId
      );

      if (mounted) {
        setState(() {
          _postinganList = postingan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadNamaDosen() async {
    try {
      final nama = await DosenService.getNamaDosen(widget.dosenId);
      if (mounted) {
        setState(() {
          _namaDosen = nama;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _namaDosen = 'Dosen Tidak Diketahui';
        });
      }
    }
  }

  // METHOD BARU: Create postingan (untuk dosen)
  Future<void> _createPostingan() async {
    final TextEditingController captionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Pengumuman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kelas: ${widget.className}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: 'Masukkan pengumuman...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caption = captionController.text.trim();
              if (caption.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengumuman tidak boleh kosong'))
                );
                return;
              }

              Navigator.pop(context);
              await _submitPostingan(caption);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: const Text('Buat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPostingan(String caption) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await PostinganService.createPostingan(
        dosenId: widget.dosenId,
        jadwalId: widget.jadwalId,
        caption: caption,
      );

      // Refresh list setelah create
      await _loadPostingan();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengumuman berhasil dibuat'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pengumuman: $e'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePostingan(int postinganId) async {
    try {
      final success = await PostinganService.deletePostingan(
        postinganId: postinganId,
        dosenId: widget.dosenId,
        jadwalId: widget.jadwalId,
      );

      if (success) {
        // Refresh list setelah delete
        _loadPostingan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil dihapus'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus postingan: $e'))
      );
    }
  }

  void _showDeleteConfirmation(int postinganId, String caption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus postingan: "${caption.length > 50 ? '${caption.substring(0, 50)}...' : caption}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal')
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePostingan(postinganId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // METHOD BARU: Refresh data
  Future<void> _refreshData() async {
    await _loadPostingan();
    await _loadNamaDosen();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFB71C1C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          // TOMBOL TAMBAH UNTUK DOSEN
          if (_userRole == 'dosen')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: _createPostingan,
              tooltip: 'Buat Pengumuman',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan informasi kelas
              Container(
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
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(25),
                      ),
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
                          Text(
                            widget.schedule, 
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userRole == 'dosen' 
                              ? 'Anda adalah pengajar' 
                              : 'Dosen: $_namaDosen',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section title dengan role-based
              Row(
                children: [
                  Text(
                    _userRole == 'dosen' ? "Kelola Pengumuman" : "Pengumuman Kelas",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_postinganList.isNotEmpty)
                    Text(
                      '${_postinganList.length} postingan',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading state
              if (_isLoading) 
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Error state
              if (_errorMessage.isNotEmpty)
                Container(
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
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),

              // Empty state
              if (!_isLoading && _errorMessage.isEmpty && _postinganList.isEmpty)
                Container(
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
                      Icon(
                        Icons.announcement_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userRole == 'dosen' 
                          ? "Belum ada pengumuman"
                          : "Belum ada pengumuman untuk kelas ini",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userRole == 'dosen'
                          ? "Buat pengumuman pertama untuk menginformasikan hal penting kepada mahasiswa"
                          : "Dosen akan memposting pengumuman penting di sini",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      if (_userRole == 'dosen') ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _createPostingan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Buat Pengumuman Pertama', 
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // List announcements dari API
              if (!_isLoading && _errorMessage.isEmpty && _postinganList.isNotEmpty)
                Column(
                  children: _postinganList.map(
                    (postingan) => _buildAnnouncementItem(
                      postingan: postingan,
                      canDelete: _userRole == 'dosen', // Hanya dosen yang bisa hapus
                      onDelete: () => _showDeleteConfirmation(postingan.id, postingan.caption),
                    ),
                  ).toList(),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem({
    required Postingan postingan,
    required bool canDelete,
    required VoidCallback onDelete,
  }) {
    final Color primaryRed = const Color(0xFFB71C1C);

    // Format tanggal dari created_at atau gunakan default
    final date = _formatDate(postingan);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryRed.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan nama dosen dan tanggal
          Row(
            children: [
              // Avatar/icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  canDelete ? Icons.person : Icons.school,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Nama dan tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaDosen,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Action button (hanya untuk dosen)
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus Pengumuman',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Garis pemisah
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          const SizedBox(height: 12),

          // Caption/isi pengumuman
          Text(
            postingan.caption, 
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),

          // Gambar (jika ada)
          if (postingan.imageUrl != null && postingan.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                postingan.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Timestamp dan info tambahan
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Diposting $date',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              const Spacer(),
              if (canDelete)
                Text(
                  'Anda yang memposting',
                  style: TextStyle(color: primaryRed, fontSize: 11, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(Postingan postingan) {
    // Untuk sementara, gunakan format sederhana berdasarkan index
    // Dalam implementasi real, gunakan field created_at dari API
    final now = DateTime.now();
    final index = _postinganList.indexOf(postingan);
    final postDate = DateTime(now.year, now.month, now.day - index);

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${postDate.day} ${months[postDate.month - 1]} ${postDate.year}';
  }
}