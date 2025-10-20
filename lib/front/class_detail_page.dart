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
    print("🚀 ClassDetail initState - className: ${widget.className}, jadwalId: ${widget.jadwalId}");
    _loadUserData().then((_) {
      // Setelah user data loaded, baru load postingan dan nama dosen
      _loadPostingan();
      _loadNamaDosen();
    });
  }

  // METHOD: Load data user
  Future<void> _loadUserData() async {
    try {
      print("🔍 START _loadUserData");
      final role = await AuthService.getUserRole();
      final name = await AuthService.getUserName();

      print("📊 User data - Role: $role, Name: $name");

      if (mounted) {
        setState(() {
          _userRole = role ?? 'mahasiswa';
          _userName = name ?? 'User';
        });
      }
      print("✅ _loadUserData completed - Role: $_userRole, Name: $_userName");
    } catch (e) {
      print("❌ ERROR in _loadUserData: $e");
    }
  }

  Future<void> _loadPostingan() async {
    try {
      print("🔄 START _loadPostingan - jadwalId: ${widget.jadwalId}, userRole: $_userRole");
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      List<Postingan> postingan = [];

      // ✅ LOGIKA BARU: Pilih method berdasarkan role user
      if (_userRole == 'dosen') {
        print("👨‍🏫 Loading postingan by dosen...");
        // Untuk dosen: ambil semua postingan yang dibuat oleh dosen ini
        postingan = await PostinganService.getPostinganByDosen(dosenId: widget.dosenId);
      } else {
        print("👨‍🎓 Loading postingan by jadwal...");
        // Untuk mahasiswa: ambil postingan berdasarkan jadwal kelas
        postingan = await PostinganService.getPostinganByJadwal(jadwalId: widget.jadwalId);
      }

      print("📊 _loadPostingan - Received ${postingan.length} postingan");

      if (mounted) {
        setState(() {
          _postinganList = postingan;
          _isLoading = false;
        });
      }
      print("✅ _loadPostingan completed - ${_postinganList.length} postingan loaded");
    } catch (e) {
      print("❌ ERROR in _loadPostingan: $e");
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
      print("🔍 START _loadNamaDosen - dosenId: ${widget.dosenId}");
      final nama = await DosenService.getNamaDosen(widget.dosenId);
      print("📊 Dosen name received: $nama");

      if (mounted) {
        setState(() {
          _namaDosen = nama;
        });
      }
      print("✅ _loadNamaDosen completed - Nama: $_namaDosen");
    } catch (e) {
      print("❌ ERROR in _loadNamaDosen: $e");
      if (mounted) {
        setState(() {
          _namaDosen = 'Dosen Tidak Diketahui';
        });
      }
    }
  }

  // METHOD: Create postingan (untuk dosen)
  Future<void> _createPostingan() async {
    print("🚀 START _createPostingan - userRole: $_userRole");

    if (_userRole != 'dosen') {
      print("⚠️ Only dosen can create postingan");
      return;
    }

    final TextEditingController judulController = TextEditingController();
    final TextEditingController kontenController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buat Pengumuman'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kelas: ${widget.className}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: judulController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Pengumuman',
                      hintText: 'Masukkan judul pengumuman...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kontenController,
                    decoration: const InputDecoration(
                      labelText: 'Isi Pengumuman',
                      hintText: 'Masukkan isi pengumuman...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print("❌ Create postingan cancelled");
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final judul = judulController.text.trim();
                  final konten = kontenController.text.trim();

                  print("📝 Validating postingan - Judul: $judul, Konten: $konten");

                  if (judul.isEmpty || konten.isEmpty) {
                    print("⚠️ Validation failed - judul or konten is empty");
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Judul dan isi pengumuman tidak boleh kosong')));
                    return;
                  }

                  print("✅ Validation passed, proceeding with submission");
                  Navigator.pop(context);
                  await _submitPostingan(judul, konten);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                child: const Text('Buat', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _submitPostingan(String judul, String konten) async {
    print("🚀 START _submitPostingan - Judul: $judul");
    try {
      setState(() {
        _isLoading = true;
      });

      // MENYESUAIKAN: Gunakan method createPostingan yang baru
      final result = await PostinganService.createPostingan(
        jadwalId: widget.jadwalId,
        judul: judul,
        konten: konten,
        // dosenId akan otomatis diambil dari service
      );

      print("📡 _submitPostingan response - Success: ${result['success']}, Message: ${result['message']}");

      if (result['success'] == true) {
        // Refresh list setelah create
        await _loadPostingan();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Pengumuman berhasil dibuat')));
        print("✅ Postingan created successfully");
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal membuat pengumuman')));
        print("❌ Postingan creation failed");
      }
    } catch (e) {
      print("❌ ERROR in _submitPostingan: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pengumuman: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePostingan(int postinganId) async {
    print("🚀 START _deletePostingan - postinganId: $postinganId");
    try {
      // MENYESUAIKAN: Gunakan method deletePostingan yang baru
      final result = await PostinganService.deletePostingan(postinganId: postinganId);

      print("📡 _deletePostingan response - Success: ${result['success']}, Message: ${result['message']}");

      if (result['success'] == true) {
        // Refresh list setelah delete
        _loadPostingan();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Postingan berhasil dihapus')));
        print("✅ Postingan deleted successfully");
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menghapus postingan')));
        print("❌ Postingan deletion failed");
      }
    } catch (e) {
      print("❌ ERROR in _deletePostingan: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus postingan: $e')));
    }
  }

  void _showDeleteConfirmation(int postinganId, String judul) {
    print("🚀 START _showDeleteConfirmation - postinganId: $postinganId");
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Postingan'),
            content: Text(
              'Apakah Anda yakin ingin menghapus postingan: "${judul.length > 50 ? '${judul.substring(0, 50)}...' : judul}"?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print("❌ Delete cancelled");
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  print("✅ Delete confirmed");
                  Navigator.pop(context);
                  _deletePostingan(postinganId);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // METHOD: Refresh data
  Future<void> _refreshData() async {
    print("🔄 START _refreshData");
    await _loadUserData();
    await _loadPostingan();
    await _loadNamaDosen();
    print("✅ _refreshData completed");
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFB71C1C);

    print(
      "🎨 Building ClassDetail UI - isLoading: $_isLoading, postinganCount: ${_postinganList.length}, userRole: $_userRole",
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            print("🔙 Navigating back");
            Navigator.pop(context);
          },
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
            onPressed: () {
              print("🔄 Manual refresh triggered");
              _refreshData();
            },
            tooltip: 'Refresh',
          ),
          // TOMBOL TAMBAH UNTUK DOSEN
          if (_userRole == 'dosen')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                print("➕ Create postingan button pressed");
                _createPostingan();
              },
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
                      decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(25)),
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
                          Text(
                            _userRole == 'dosen' ? 'Anda adalah pengajar' : 'Dosen: $_namaDosen',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (_userRole == 'dosen') ...[
                            const SizedBox(height: 2),
                            Text(
                              'ID Dosen: ${widget.dosenId}',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
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
                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          print("🔄 Retry button pressed from error state");
                          _refreshData();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                      Icon(Icons.announcement_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _userRole == 'dosen' ? "Belum ada pengumuman" : "Belum ada pengumuman untuk kelas ini",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
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
                          onPressed: () {
                            print("➕ Create first postingan button pressed");
                            _createPostingan();
                          },
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
                  children:
                      _postinganList.map((postingan) {
                        print("🎨 Building postingan item: ${postingan.judul}");
                        return _buildAnnouncementItem(
                          postingan: postingan,
                          canDelete: _userRole == 'dosen', // Hanya dosen yang bisa hapus
                          onDelete: () => _showDeleteConfirmation(postingan.id, postingan.judul),
                        );
                      }).toList(),
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

    // Format tanggal dari created_at
    final date = _formatDate(postingan);

    print("🎨 Building announcement item: ${postingan.judul}");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryRed.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
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
                decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(18)),
                child: Icon(canDelete ? Icons.person : Icons.school, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),

              // Nama dan tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_namaDosen, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

              // Action button (hanya untuk dosen)
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () {
                    print("🗑️ Delete button pressed for postingan: ${postingan.id}");
                    onDelete();
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus Pengumuman',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Garis pemisah
          Container(height: 1, color: Colors.grey[200]),

          const SizedBox(height: 12),

          // Judul pengumuman
          Text(
            postingan.judul,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),

          const SizedBox(height: 8),

          // Konten/isi pengumuman
          Text(postingan.konten, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),

          // File/Gambar (jika ada)
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

          // Timestamp dan info tambahan
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('Diposting $date', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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
    print("📅 Formatting date for postingan: ${postingan.id}");

    // Prioritaskan menggunakan createdAt dari API
    if (postingan.createdAt != null) {
      final date = postingan.createdAt!;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
      print("✅ Using API createdAt: $formattedDate");
      return formattedDate;
    }

    // Fallback: gunakan format berdasarkan index (untuk demo)
    final now = DateTime.now();
    final index = _postinganList.indexOf(postingan);
    final postDate = DateTime(now.year, now.month, now.day - index);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formattedDate = '${postDate.day} ${months[postDate.month - 1]} ${postDate.year}';

    print("⚠️ Using fallback date (index-based): $formattedDate");
    return formattedDate;
  }

  @override
  void dispose() {
    print("🧹 ClassDetail disposed");
    super.dispose();
  }
}
