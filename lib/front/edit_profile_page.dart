import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../back/auth_service.dart'; // pastikan sesuai path AuthService kamu

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  void _debugCheckSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== DEBUG SharedPreferences ===");
    print("mahasiswa_id: ${prefs.getInt('mahasiswa_id')}");
    print("user_id: ${prefs.getInt('user_id')}");
    print("mahasiswa_nama: ${prefs.getString('userName')}");
    print("mahasiswa_nim: ${prefs.getString('mahasiswa_nim')}");
    print("mahasiswa_kelas: ${prefs.getString('mahasiswa_kelas')}");
    print("mahasiswa_prodi: ${prefs.getString('mahasiswa_prodi')}");
    print("===============================");
  }

  int _selectedIndex = 2; // default: Profile aktif (karena kanan)

  // Controller untuk form
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _prodiController = TextEditingController();

  int? mahasiswaId;
  int? userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _debugCheckSharedPreferences();
  }

  // Ambil data user dari SharedPreferences
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      mahasiswaId = prefs.getInt('mahasiswa_id');
      userId = prefs.getInt('user_id');
      _namaController.text = prefs.getString('userName') ?? '';
      _nimController.text = prefs.getString('mahasiswa_nim') ?? '';
      _kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
      _prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
    });
  }

  // Fungsi gabungan untuk menyimpan kedua profil
  void _saveAllProfiles() async {
    if (mahasiswaId == null || userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ID Mahasiswa atau User tidak ditemukan!")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Jalankan kedua update secara berurutan
      final resultMahasiswa = await AuthService.updateMahasiswa(
        id: mahasiswaId!,
        idu: userId!,
        nama: _namaController.text,
        nim: _nimController.text,
        prodi: _prodiController.text,
        kelas: _kelasController.text,
      );

      final resultUser = await AuthService.updateUser(idu: userId!, nama: _namaController.text);

      setState(() {
        _isLoading = false;
      });

      // Cek hasil kedua request
      bool mahasiswaSuccess = resultMahasiswa['statusCode'] == 200;
      bool userSuccess = resultUser['statusCode'] == 200;

      if (mahasiswaSuccess && userSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua profil berhasil diperbarui")));
      } else if (mahasiswaSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profil mahasiswa berhasil, tapi profil user gagal")));
      } else if (userSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profil user berhasil, tapi profil mahasiswa gagal")));
      } else {
        String errorMessage = "Kedua update gagal: ";
        if (resultMahasiswa['data']?['message'] != null) {
          errorMessage += "Mahasiswa: ${resultMahasiswa['data']['message']} ";
        }
        if (resultUser['data']?['message'] != null) {
          errorMessage += "User: ${resultUser['data']['message']}";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage.isEmpty ? "Unknown error" : errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Bottom nav
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/class');
    } else if (index == 2) {
      // Tetap di ProfilePage
    }
  }

  // Logout dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
              onPressed: () async {
                await AuthService.logout(); // pake AuthService biar konsisten
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE57373)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(radius: 50, backgroundImage: AssetImage("assets/profile.jpg")),
                          const SizedBox(height: 10),
                          const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: "Nama", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _nimController,
                      decoration: const InputDecoration(labelText: "NIM", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _kelasController,
                      decoration: const InputDecoration(labelText: "Kelas", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _prodiController,
                      decoration: const InputDecoration(labelText: "Prodi", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 25),

                    // Tombol Save (sekarang menjalankan kedua fungsi)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _saveAllProfiles,
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tombol Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB71C1C),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showLogoutDialog,
                        child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // Bottom nav bar
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: const Color(0xFFB71C1C),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
