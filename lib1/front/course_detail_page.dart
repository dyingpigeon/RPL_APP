import 'package:flutter/material.dart';

class CourseDetailPage extends StatelessWidget {
  final String judul;
  final String deskripsi;
  final String deadline;
  final String fileUrl;
  final int jadwalId;

  const CourseDetailPage({
    super.key,
    required this.judul,
    required this.jadwalId,
    required this.deskripsi,
    required this.deadline,
    required this.fileUrl,
  });

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
        title: Text(judul, style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        // HAPUS PADDING DI SINI agar container bisa memenuhi lebar layar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan informasi tugas
            Container(
              padding: const EdgeInsets.all(16), // ← TAMBAHKAN PADDING DI CONTAINER HEADER
              child: Row(
                children: [
                  const CircleAvatar(radius: 26, backgroundImage: AssetImage('assets/profile.jpg')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judul,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text("Deadline: $deadline", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Container detail tugas - MEMENUHI LAYAR
            Container(
              width: double.infinity, // ← PASTIKAN LEBAR MEMENUHI
              margin: const EdgeInsets.symmetric(horizontal: 0), // ← HILANGKAN MARGIN HORIZONTAL
              padding: const EdgeInsets.all(16), // ← TAMBAHKAN PADDING INTERNAL
              decoration: BoxDecoration(
                border: Border.all(color: primaryRed, width: 1.5),
                borderRadius: BorderRadius.circular(0), // ← OPSIONAL: hilangkan border radius untuk efek full width
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Deadline: $deadline", style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 6),
                  const Text("100 points", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(
                    deskripsi.isNotEmpty ? deskripsi : "Tidak ada deskripsi",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Menampilkan file URL jika ada
                  if (fileUrl.isNotEmpty) ...[
                    const Text("File Terlampir:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(fileUrl, style: const TextStyle(fontSize: 14, color: Colors.blue)),
                  ],

                  // Menampilkan jadwal ID untuk debugging
                  const SizedBox(height: 10),
                  Text("Jadwal ID: $jadwalId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // File upload section - JUGA MEMENUHI LAYAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0), // ← HILANGKAN MARGIN HORIZONTAL
              child: GestureDetector(
                onTap: () {
                  _showFileUploadOptions(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(0), // ← OPSIONAL: hilangkan border radius
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.upload_file, color: Colors.black54),
                      SizedBox(width: 8),
                      Text("Choose a File or Drag it here"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFileUploadOptions(BuildContext context) {
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
}
