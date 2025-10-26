class EditProfileModel {
  final String? nama;
  final String? nim;
  final String? kelas;
  final String? prodi;
  final String? nip;
  final String? photoUrl;
  final int? mahasiswaId;
  final int? dosenId;
  final int? userId;
  final String userRole;
  final bool isLoading;

  EditProfileModel({
    this.nama,
    this.nim,
    this.kelas,
    this.prodi,
    this.nip,
    this.photoUrl,
    this.mahasiswaId,
    this.dosenId,
    this.userId,
    this.userRole = 'mahasiswa',
    this.isLoading = false,
  });

  EditProfileModel copyWith({
    String? nama,
    String? nim,
    String? kelas,
    String? prodi,
    String? nip,
    String? photoUrl,
    int? mahasiswaId,
    int? dosenId,
    int? userId,
    String? userRole,
    bool? isLoading,
  }) {
    return EditProfileModel(
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      kelas: kelas ?? this.kelas,
      prodi: prodi ?? this.prodi,
      nip: nip ?? this.nip,
      photoUrl: photoUrl ?? this.photoUrl,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      dosenId: dosenId ?? this.dosenId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isMahasiswa => userRole == 'mahasiswa';
  bool get isDosen => userRole == 'dosen';
  bool get hasUserData => userId != null;
  bool get hasMahasiswaData => mahasiswaId != null && isMahasiswa;
  bool get hasDosenData => dosenId != null && isDosen;
  bool get hasProfilePhoto => photoUrl != null && photoUrl!.isNotEmpty;

  // Validasi form
  bool get isNamaValid => nama != null && nama!.isNotEmpty;
  bool get isNimValid => !isMahasiswa || (nim != null && nim!.isNotEmpty);
  bool get isKelasValid => !isMahasiswa || (kelas != null && kelas!.isNotEmpty);
  bool get isProdiValid => !isMahasiswa || (prodi != null && prodi!.isNotEmpty);
  bool get isNipValid => !isDosen || (nip != null && nip!.isNotEmpty);

  // Comprehensive form validation
  bool get isFormValid {
    if (!isNamaValid) return false;

    if (isMahasiswa) {
      return isNimValid && isKelasValid && isProdiValid;
    } else if (isDosen) {
      return isNipValid;
    }

    return true;
  }

  // Getters untuk save button state - FIXED LOGIC
  bool get canSave =>
      !isLoading &&
      hasUserData &&
      isFormValid &&
      ((isMahasiswa && hasMahasiswaData && nim != null && nim!.isNotEmpty && kelas != null && kelas!.isNotEmpty) ||
          (isDosen && hasDosenData && nip != null && nip!.isNotEmpty));

  // Getters untuk display purposes
  String get displayName => nama ?? 'Tidak ada nama';
  String get displayNim => nim ?? 'Tidak ada NIM';
  String get displayKelas => kelas ?? 'Tidak ada kelas';
  String get displayProdi => prodi ?? 'Tidak ada prodi';
  String get displayNip => nip ?? 'Tidak ada NIP';
  String get displayRole => isMahasiswa ? 'Mahasiswa' : 'Dosen';

  @override
  String toString() {
    return 'EditProfileModel(\n'
        '  nama: $nama,\n'
        '  nim: $nim,\n'
        '  kelas: $kelas,\n'
        '  prodi: $prodi,\n'
        '  nip: $nip,\n'
        '  mahasiswaId: $mahasiswaId,\n'
        '  dosenId: $dosenId,\n'
        '  userId: $userId,\n'
        '  userRole: $userRole,\n'
        '  isLoading: $isLoading,\n'
        '  isFormValid: $isFormValid,\n'
        '  canSave: $canSave\n'
        ')';
  }
}
