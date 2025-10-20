import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  void _debugCheckSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== DEBUG SharedPreferences ===");
    print("user_id: ${prefs.getInt('user_id')}");
    print("userName: ${prefs.getString('userName')}");
    print("userRole: ${prefs.getString('userRole')}");

    final role = prefs.getString('userRole');
    if (role == 'mahasiswa') {
      print("mahasiswa_id: ${prefs.getInt('mahasiswa_id')}");
      print("mahasiswa_nim: ${prefs.getString('mahasiswa_nim')}");
      print("mahasiswa_kelas: ${prefs.getString('mahasiswa_kelas')}");
      print("mahasiswa_prodi: ${prefs.getString('mahasiswa_prodi')}");
    } else if (role == 'dosen') {
      print("dosen_id: ${prefs.getInt('dosen_id')}");
      print("dosen_nama: ${prefs.getString('dosen_nama')}");
      print("dosen_nip: ${prefs.getString('dosen_nip')}");
    }
    print("===============================");
  }

  // int _selectedIndex = 2;

  // Controller untuk form
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _prodiController = TextEditingController();
  final TextEditingController _nipController = TextEditingController(); // NEW: untuk dosen

  int? mahasiswaId;
  int? dosenId; // NEW: untuk dosen
  int? userId;
  String userRole = 'mahasiswa'; // NEW: untuk menentukan role
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

    // Dapatkan role user
    final role = prefs.getString('userRole') ?? 'mahasiswa';

    setState(() {
      userRole = role;
      userId = prefs.getInt('user_id');
      _namaController.text = prefs.getString('userName') ?? '';
    });

    // Load data berdasarkan role
    if (role == 'mahasiswa') {
      setState(() {
        mahasiswaId = prefs.getInt('mahasiswa_id');
        _nimController.text = prefs.getString('mahasiswa_nim') ?? '';
        _kelasController.text = prefs.getString('mahasiswa_kelas') ?? '';
        _prodiController.text = prefs.getString('mahasiswa_prodi') ?? '';
      });
    } else if (role == 'dosen') {
      setState(() {
        dosenId = prefs.getInt('dosen_id');
        _nipController.text = prefs.getString('dosen_nip') ?? '';
      });
    }
  }

  // Fungsi untuk menyimpan profil berdasarkan role
  void _saveProfile() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID User tidak ditemukan!")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (userRole == 'mahasiswa') {
        await _saveMahasiswaProfile();
      } else if (userRole == 'dosen') {
        await _saveDosenProfile();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Simpan profil mahasiswa
  Future<void> _saveMahasiswaProfile() async {
    if (mahasiswaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Mahasiswa tidak ditemukan!")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mahasiswa berhasil diperbarui")));
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
  }

  // NEW: Simpan profil dosen
  Future<void> _saveDosenProfile() async {
    if (dosenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Dosen tidak ditemukan!")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Update data dosen
    final resultDosen = await AuthService.updateDosen(
      id: dosenId!,
      nama: _namaController.text,
      nip: _nipController.text,
    );

    // Update data user (nama)
    final resultUser = await AuthService.updateUser(idu: userId!, nama: _namaController.text);

    setState(() {
      _isLoading = false;
    });

    // Cek hasil kedua request
    bool dosenSuccess = resultDosen['statusCode'] == 200;
    bool userSuccess = resultUser['statusCode'] == 200;

    if (dosenSuccess && userSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil dosen berhasil diperbarui")));
    } else if (dosenSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil dosen berhasil, tapi profil user gagal")));
    } else if (userSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil user berhasil, tapi profil dosen gagal")));
    } else {
      String errorMessage = "Kedua update gagal: ";
      if (resultDosen['data']?['message'] != null) {
        errorMessage += "Dosen: ${resultDosen['data']['message']} ";
      }
      if (resultUser['data']?['message'] != null) {
        errorMessage += "User: ${resultUser['data']['message']}";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage.isEmpty ? "Unknown error" : errorMessage)));
    }
  }

  // Widget untuk form mahasiswa
  Widget _buildMahasiswaForm() {
    return Column(
      children: [
        // Nama (read-only untuk mahasiswa juga)
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: "Nama",
            border: OutlineInputBorder(),
            filled: true,
            //fillColor: Colors.grey100,
          ),
          readOnly: true,
          style: TextStyle(color: Colors.grey[600]),
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
          readOnly: true,
        ),
      ],
    );
  }

  // NEW: Widget untuk form dosen
  Widget _buildDosenForm() {
    return Column(
      children: [
        // Nama (read-only untuk dosen)
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: "Nama",
            border: OutlineInputBorder(),
            filled: true,
            //fillColor: Colors.grey100,
          ),
          readOnly: true,
          style: TextStyle(color: Colors.grey[100]),
        ),
        const SizedBox(height: 15),

        // NIP (dapat diisi)
        TextFormField(
          controller: _nipController,
          decoration: const InputDecoration(
            labelText: "NIP",
            border: OutlineInputBorder(),
            hintText: "Masukkan NIP Anda",
          ),
          keyboardType: TextInputType.number,
        ),

        // Informasi tambahan untuk dosen
        // const SizedBox(height: 15),
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.blue[50],
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: Colors.blue),
        //   ),
        //   child: const Row(
        //     children: [
        //       Icon(Icons.info_outline, color: Colors.blue, size: 20),
        //       SizedBox(width: 8),
        //       Expanded(
        //         child: Text(
        //           "Sebagai dosen, Anda hanya dapat mengupdate NIP. Nama tidak dapat diubah.",
        //           style: TextStyle(fontSize: 12, color: Colors.blue),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  // Bottom nav
  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });

  //   if (index == 0) {
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } else if (index == 1) {
  //     Navigator.pushReplacementNamed(context, '/class');
  //   } else if (index == 2) {
  //     // Tetap di ProfilePage
  //   }
  // }

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
                await AuthService.logout();
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
                    // Positioned(
                    //   left: 16,
                    //   top: 16,
                    //   child: IconButton(
                    //     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    //     onPressed: () {
                    //       Navigator.pop(context);
                    //     },
                    //   ),
                    // ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(radius: 50, backgroundImage: AssetImage("assets/profile.jpg")),
                          const SizedBox(height: 10),
                          Text(
                            "Edit Profile - ${userRole == 'mahasiswa' ? 'Mahasiswa' : 'Dosen'}",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userRole == 'mahasiswa' ? "Update data mahasiswa" : "Update data dosen",
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form input berdasarkan role
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Tampilkan form berdasarkan role
                    if (userRole == 'mahasiswa') _buildMahasiswaForm() else if (userRole == 'dosen') _buildDosenForm(),

                    const SizedBox(height: 25),

                    // Tombol Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                  "Simpan Profil ${userRole == 'mahasiswa' ? 'Mahasiswa' : 'Dosen'}",
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tombol Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
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
      // bottomNavigationBar: ClipRRect(
      //   borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      //   child: BottomNavigationBar(
      //     currentIndex: _selectedIndex,
      //     onTap: _onItemTapped,
      //     selectedItemColor: Colors.white,
      //     unselectedItemColor: Colors.white70,
      //     backgroundColor: const Color(0xFFB71C1C),
      //     items: const [
      //       BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //       BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Class"),
      //       BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      //     ],
      //   ),
      // ),
    );
  }
}
