import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/edit_profile_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditProfileController(),
      child: Consumer<EditProfileController>(
        builder: (context, controller, child) {
          return ScaffoldMessenger(
            key: controller.scaffoldMessengerKey, // ✅ TAMBAHKAN INI
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        _buildHeaderSection(controller),
                        const SizedBox(height: 20),

                        // Form Section
                        _buildFormSection(controller),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(EditProfileController controller) {
    return Container(
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
          // Tombol back di kiri atas
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // PROFILE PHOTO
                _buildProfilePhoto(controller),
                const SizedBox(height: 10),
                Text(
                  "Edit Profile - ${controller.getRoleDisplayName()}",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.model.isMahasiswa ? "Update data mahasiswa" : "Update data dosen",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(EditProfileController controller) {
    if (controller.hasProfilePhoto) {
      return CachedNetworkImage(
        imageUrl: controller.userPhotoUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(radius: 50, backgroundImage: imageProvider),
        errorWidget: (context, url, error) {
          print('❌ CachedNetworkImage Error: $error');
          print('❌ Failed URL: $url');
          return CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          );
        },
        // ========== CONFIGURATION ==========
        cacheKey: controller.userPhotoUrl!,
        maxWidthDiskCache: 300,
        maxHeightDiskCache: 300,
        httpHeaders: {"Accept": "image/*", "User-Agent": "Flutter App"},
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeIn,
        useOldImageOnUrlChange: true,
        memCacheWidth: 200,
        memCacheHeight: 200,
        progressIndicatorBuilder:
            (context, url, downloadProgress) => CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Stack(
                children: [
                  const CircularProgressIndicator(
                    value: null, // Indeterminate
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  if (downloadProgress.progress != null)
                    CircularProgressIndicator(
                      value: downloadProgress.progress,
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2,
                    ),
                ],
              ),
            ),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white.withOpacity(0.3),
        child: const Icon(Icons.person, size: 40, color: Colors.white),
      );
    }
  }

  Widget _buildFormSection(EditProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Tampilkan form berdasarkan role
          if (controller.model.isMahasiswa)
            _buildMahasiswaForm(controller)
          else if (controller.model.isDosen)
            _buildDosenForm(controller),

          const SizedBox(height: 25),

          // Save Button
          _buildSaveButton(controller),
          const SizedBox(height: 15),

          // Logout Button
          _buildLogoutButton(controller),
        ],
      ),
    );
  }

  Widget _buildMahasiswaForm(EditProfileController controller) {
    return Column(
      children: [
        // Nama (read-only untuk mahasiswa)
        TextFormField(
          controller: controller.namaController,
          decoration: const InputDecoration(
            labelText: "Nama",
            border: OutlineInputBorder(),
            filled: true,
            prefixIcon: Icon(Icons.person),
          ),
          readOnly: true,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),

        // NIM
        TextFormField(
          controller: controller.nimController,
          decoration: const InputDecoration(
            labelText: "NIM",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 15),

        // Kelas
        TextFormField(
          controller: controller.kelasController,
          decoration: const InputDecoration(
            labelText: "Kelas",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.class_),
          ),
        ),
        const SizedBox(height: 15),

        // Prodi (read-only)
        TextFormField(
          controller: controller.prodiController,
          decoration: const InputDecoration(
            labelText: "Prodi",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
            filled: true,
          ),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildDosenForm(EditProfileController controller) {
    return Column(
      children: [
        // Nama (read-only untuk dosen)
        TextFormField(
          controller: controller.namaController,
          decoration: const InputDecoration(
            labelText: "Nama",
            border: OutlineInputBorder(),
            filled: true,
            prefixIcon: Icon(Icons.person),
          ),
          readOnly: true,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),

        // NIP
        TextFormField(
          controller: controller.nipController,
          decoration: const InputDecoration(
            labelText: "NIP",
            border: OutlineInputBorder(),
            hintText: "Masukkan NIP Anda",
            prefixIcon: Icon(Icons.badge),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSaveButton(EditProfileController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed:
            // ✅ TOMBOL SELALU AKTIF - HAPUS KONDISI canSave
            () => controller.saveProfile(),
        child:
            controller.model.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(controller.getSaveButtonText(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
      ),
    );
  }

  Widget _buildLogoutButton(EditProfileController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.primaryRed,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => controller.showLogoutDialog(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 8),
            Text("Logout", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
