class ClassModel {
  List<dynamic> jadwalList;
  bool isLoading;
  String? errorMessage;
  String userName;
  String userRole;
  DateTime currentDate;

  ClassModel({
    List<dynamic>? jadwalList,
    this.isLoading = true,
    this.errorMessage,
    this.userName = "User",
    this.userRole = "mahasiswa",
    DateTime? currentDate,
  })  : jadwalList = jadwalList ?? [],
        currentDate = currentDate ?? DateTime.now();

  ClassModel copyWith({
    List<dynamic>? jadwalList,
    bool? isLoading,
    String? errorMessage,
    String? userName,
    String? userRole,
    DateTime? currentDate,
  }) {
    return ClassModel(
      jadwalList: jadwalList ?? this.jadwalList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      currentDate: currentDate ?? this.currentDate,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => jadwalList.isEmpty;
  bool get isMahasiswa => userRole == 'mahasiswa';
  bool get isDosen => userRole == 'dosen';
  String get greeting => isMahasiswa ? 'Hi, $userName!' : 'Selamat Mengajar, $userName!';
  String get emptyMessage => isMahasiswa 
      ? "Tidak ada jadwal kelas untuk semester ini" 
      : "Tidak ada jadwal mengajar untuk saat ini";
  String get errorTitle => isMahasiswa 
      ? "Tidak ada jadwal ditemukan untuk semester ini" 
      : "Tidak ada jadwal mengajar ditemukan";
}