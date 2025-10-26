import 'package:flutter/material.dart';
import '../models/class_detail_model.dart';
import '../services/postingan_service.dart';
import '../services/dosen_service.dart';
import '../services/auth_service.dart';
import '../services/tugas_service.dart'; // ✅ IMPORT BARU

class ClassDetailController with ChangeNotifier {
  final String className;
  final String schedule;
  final int dosenId;
  final int jadwalId;

  ClassDetailModel _model = ClassDetailModel();
  final Color primaryRed = const Color(0xFFB71C1C);

  ClassDetailController({
    required this.className,
    required this.schedule,
    required this.dosenId,
    required this.jadwalId,
  }) {
    print("🚀 ClassDetailController created - className: $className, jadwalId: $jadwalId");
    _initializeData();
  }

  ClassDetailModel get model => _model;

  Future<void> _initializeData() async {
    await _loadUserData().then((_) {
      _loadPostingan();
      _loadNamaDosen();
    });
  }

  Future<void> _loadUserData() async {
    try {
      print("🔍 START _loadUserData");
      final role = await AuthService.getUserRole();
      final name = await AuthService.getUserName();

      print("📊 User data - Role: $role, Name: $name");

      _model = _model.copyWith(userRole: role ?? 'mahasiswa', userName: name ?? 'User');
      notifyListeners();
      print("✅ _loadUserData completed - Role: ${_model.userRole}, Name: ${_model.userName}");
    } catch (e) {
      print("❌ ERROR in _loadUserData: $e");
    }
  }

  Future<void> _loadPostingan() async {
    try {
      print("🔄 START _loadPostingan - jadwalId: $jadwalId, userRole: ${_model.userRole}");
      _model = _model.copyWith(isLoading: true, errorMessage: '');
      notifyListeners();

      List<Postingan> postingan = [];

      if (_model.isDosen) {
        print("👨‍🏫 Loading postingan by dosen...");
        postingan = await PostinganService.getPostinganByDosen(dosenId: dosenId);
      } else {
        print("👨‍🎓 Loading postingan by jadwal...");
        postingan = await PostinganService.getPostinganByJadwal(jadwalId: jadwalId);
      }

      print("📊 _loadPostingan - Received ${postingan.length} postingan");

      _model = _model.copyWith(postinganList: postingan, isLoading: false);
      notifyListeners();
      print("✅ _loadPostingan completed - ${_model.postinganList.length} postingan loaded");
    } catch (e) {
      print("❌ ERROR in _loadPostingan: $e");
      _model = _model.copyWith(isLoading: false, errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<void> _loadNamaDosen() async {
    try {
      print("🔍 START _loadNamaDosen - dosenId: $dosenId");
      final nama = await DosenService.getNamaDosen(dosenId);
      print("📊 Dosen name received: $nama");

      _model = _model.copyWith(namaDosen: nama);
      notifyListeners();
      print("✅ _loadNamaDosen completed - Nama: ${_model.namaDosen}");
    } catch (e) {
      print("❌ ERROR in _loadNamaDosen: $e");
      _model = _model.copyWith(namaDosen: 'Dosen Tidak Diketahui');
      notifyListeners();
    }
  }

  // ✅ METHOD BARU: CREATE TUGAS
  Future<void> createTugas(BuildContext context, Map<String, dynamic> tugasData) async {
    try {
      print("🚀 START createTugas - Data: $tugasData");

      // Validasi data
      if (tugasData["judul"] == null || tugasData["judul"]!.isEmpty) {
        throw Exception("Judul tugas tidak boleh kosong");
      }

      if (tugasData["deadline"] == null || tugasData["deadline"]!.isEmpty) {
        throw Exception("Deadline tugas tidak boleh kosong");
      }

      _model = _model.copyWith(isLoading: true);
      notifyListeners();

      final result = await TugasService.postTugas(
        judul: tugasData["judul"]!,
        deskripsi: tugasData["deskripsi"] ?? "",
        deadline: tugasData["deadline"]!,
        jadwalId: jadwalId, // Gunakan jadwalId dari controller
      );

      print("📡 createTugas response - Success: ${result['success']}");

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Tugas berhasil dibuat'), backgroundColor: Colors.green),
        );
        print("✅ Tugas created successfully");

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal membuat tugas'), backgroundColor: Colors.red),
        );
        print("❌ Tugas creation failed");
      }
    } catch (e) {
      print("❌ ERROR in createTugas: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat tugas: $e'), backgroundColor: Colors.red));
    } finally {
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> createPostingan(BuildContext context, {String? content}) async {
    print("🚀 START createPostingan - userRole: ${_model.userRole}");

    if (!_model.canCreatePostingan) {
      print("⚠️ Only dosen can create postingan");
      return;
    }

    // Jika ada content, langsung buat postingan tanpa dialog
    if (content != null && content.isNotEmpty) {
      await _submitPostingan(context, "Pengumuman", content);
      return;
    }

    // final TextEditingController judulController = TextEditingController();
    // final TextEditingController kontenController = TextEdirrtingController();

    // showDialog(
    //   context: context,
    //   builder:
    //       (context) => AlertDialog(
    //         title: const Text('Buat Pengumuman'),
    //         content: SingleChildScrollView(
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               Text('Kelas: $className', style: const TextStyle(fontSize: 14, color: Colors.grey)),
    //               const SizedBox(height: 16),
    //               TextField(
    //                 controller: judulController,
    //                 decoration: const InputDecoration(
    //                   labelText: 'Judul Pengumuman',
    //                   hintText: 'Masukkan judul pengumuman...',
    //                   border: OutlineInputBorder(),
    //                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    //                 ),
    //                 maxLines: 1,
    //                 textInputAction: TextInputAction.next,
    //               ),
    //               const SizedBox(height: 12),
    //               TextField(
    //                 controller: kontenController,
    //                 decoration: const InputDecoration(
    //                   labelText: 'Isi Pengumuman',
    //                   hintText: 'Masukkan isi pengumuman...',
    //                   border: OutlineInputBorder(),
    //                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    //                 ),
    //                 maxLines: 4,
    //                 textInputAction: TextInputAction.done,
    //               ),
    //             ],
    //           ),
    //         ),
    //         actions: [
    //           TextButton(
    //             onPressed: () {
    //               print("❌ Create postingan cancelled");
    //               Navigator.pop(context);
    //             },
    //             child: const Text('Batal'),
    //           ),
    //           ElevatedButton(
    //             onPressed: () async {
    //               final judul = judulController.text.trim();
    //               final konten = kontenController.text.trim();

    //               print("📝 Validating postingan - Judul: $judul, Konten: $konten");

    //               if (judul.isEmpty || konten.isEmpty) {
    //                 print("⚠️ Validation failed - judul or konten is empty");
    //                 ScaffoldMessenger.of(
    //                   context,
    //                 ).showSnackBar(const SnackBar(content: Text('Judul dan isi pengumuman tidak boleh kosong')));
    //                 return;
    //               }

    //               print("✅ Validation passed, proceeding with submission");
    //               Navigator.pop(context);
    //               await _submitPostingan(context, judul, konten);
    //             },
    //             style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
    //             child: const Text('Buat', style: TextStyle(color: Colors.white)),
    //           ),
    //         ],
    //       ),
    // );
  }

  Future<void> _submitPostingan(BuildContext context, String judul, String konten) async {
    print("🚀 START _submitPostingan - Judul: $judul");
    try {
      _model = _model.copyWith(isLoading: true);
      notifyListeners();

      final result = await PostinganService.createPostingan(jadwalId: jadwalId, judul: judul, konten: konten);

      print("📡 _submitPostingan response - Success: ${result['success']}, Message: ${result['message']}");

      if (result['success'] == true) {
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
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> deletePostingan(BuildContext context, int postinganId, String judul) async {
    print("🚀 START deletePostingan - postinganId: $postinganId");

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
                onPressed: () async {
                  print("✅ Delete confirmed");
                  Navigator.pop(context);
                  await _performDeletePostingan(context, postinganId);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _performDeletePostingan(BuildContext context, int postinganId) async {
    try {
      final result = await PostinganService.deletePostingan(postinganId: postinganId);

      print("📡 _deletePostingan response - Success: ${result['success']}, Message: ${result['message']}");

      if (result['success'] == true) {
        await _loadPostingan();
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

  Future<void> refreshData() async {
    print("🔄 START refreshData");
    await _loadUserData();
    await _loadPostingan();
    await _loadNamaDosen();
    print("✅ refreshData completed");
  }

  String formatDate(Postingan postingan) {
    print("📅 Formatting date for postingan: ${postingan.id}");

    if (postingan.createdAt != null) {
      final date = postingan.createdAt!;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
      print("✅ Using API createdAt: $formattedDate");
      return formattedDate;
    }

    final now = DateTime.now();
    final index = _model.postinganList.indexOf(postingan);
    final postDate = DateTime(now.year, now.month, now.day - index);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formattedDate = '${postDate.day} ${months[postDate.month - 1]} ${postDate.year}';

    print("⚠️ Using fallback date (index-based): $formattedDate");
    return formattedDate;
  }

  void navigateBack(BuildContext context) {
    print("🔙 Navigating back");
    Navigator.pop(context);
  }
}
