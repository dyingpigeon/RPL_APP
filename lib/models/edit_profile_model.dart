class EditProfileModel {
  String? nama;
  String? nim;
  String? kelas;
  String? prodi;
  String? nip;
  String? photoUrl; // Tambahkan field foto
  int? mahasiswaId;
  int? dosenId;
  int? userId;
  String userRole;
  bool isLoading;

  EditProfileModel({
    this.nama,
    this.nim,
    this.kelas,
    this.prodi,
    this.nip,
    this.photoUrl, // Tambahkan di constructor
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
    String? photoUrl, // Tambahkan di copyWith
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
      photoUrl: photoUrl ?? this.photoUrl, // Include photoUrl
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
  bool get hasProfilePhoto => photoUrl != null && photoUrl!.isNotEmpty; // Tambahkan getter
  bool get canSave => !isLoading && hasUserData && ((isMahasiswa && hasMahasiswaData) || (isDosen && hasDosenData));
}
