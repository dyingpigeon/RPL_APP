import 'package:flutter/material.dart';
import 'package:elearning_rpl_5d/back/postingan_service.dart';
import 'package:elearning_rpl_5d/back/dosen_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPostingan();
    _loadNamaDosen();
  }

  Future<void> _loadPostingan() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final postingan = await PostinganService.getPostingan(dosenId: widget.dosenId, jadwalId: widget.jadwalId);

      setState(() {
        _postinganList = postingan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadNamaDosen() async {
    try {
      final nama = await DosenService.getNamaDosen(widget.dosenId);
      setState(() {
        _namaDosen = nama;
      });
    } catch (e) {
      setState(() {
        _namaDosen = 'Dosen Tidak Diketahui';
      });
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan berhasil dihapus')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus postingan: $e')));
    }
  }

  void _showDeleteConfirmation(int postinganId, String caption) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Postingan'),
            content: Text(
              'Apakah Anda yakin ingin menghapus postingan: "${caption.length > 50 ? '${caption.substring(0, 50)}...' : caption}"?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.className, style: const TextStyle(color: Colors.black)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _loadPostingan)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan informasi kelas
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.schedule, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Announcement section
            const Text("Announce something", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Loading state
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Error state
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _loadPostingan, child: const Text('Coba Lagi')),
                  ],
                ),
              ),

            // List announcements dari API
            if (!_isLoading && _errorMessage.isEmpty)
              ..._postinganList.map(
                (postingan) => _buildAnnouncementItem(
                  postingan: postingan,
                  onDelete: () => _showDeleteConfirmation(postingan.id, postingan.caption),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem({required Postingan postingan, required VoidCallback onDelete}) {
    final Color primaryRed = const Color(0xFFB71C1C);

    // Format tanggal dari created_at atau gunakan default
    final date = _formatDate(postingan);

    // Tentukan apakah user bisa menghapus (contoh: hanya postingan terbaru yang bisa dihapus)
    final canDelete = _canDeletePostingan(postingan);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: primaryRed, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan nama dosen dan tanggal
          Row(
            children: [
              // Checkbox
              Checkbox(value: false, onChanged: (value) {}, activeColor: primaryRed),
              const SizedBox(width: 8),

              // Nama dan tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaDosen, // ← Sekarang menggunakan data dari API
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

              // Action button
              IconButton(
                icon: Icon(canDelete ? Icons.delete : Icons.send, color: primaryRed),
                onPressed: canDelete ? onDelete : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Caption/isi pengumuman
          Text(postingan.caption, style: const TextStyle(fontSize: 14, color: Colors.black87)),

          // Gambar (jika ada)
          if (postingan.imageUrl != null && postingan.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                postingan.imageUrl!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(Postingan postingan) {
    // Anda bisa menambahkan field created_at di model Postingan
    // Untuk sementara, gunakan format sederhana
    final now = DateTime.now();
    final postDate = DateTime(now.year, now.month, now.day - _postinganList.indexOf(postingan));

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[postDate.month - 1]} ${postDate.day}';
  }

  bool _canDeletePostingan(Postingan postingan) {
    // Logic untuk menentukan apakah postingan bisa dihapus
    // Contoh: hanya postingan terbaru (index 0) yang bisa dihapus
    return _postinganList.indexOf(postingan) == 0;
  }
}
