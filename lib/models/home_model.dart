class HomeModel {
  String userName;
  String userRole;
  bool isLoading;
  DateTime currentDate;
  List<Map<String, dynamic>> mataKuliah;
  List<Map<String, dynamic>> tugas;

  HomeModel({
    this.userName = "User",
    this.userRole = "mahasiswa",
    this.isLoading = true,
    DateTime? currentDate,
    List<Map<String, dynamic>>? mataKuliah,
    List<Map<String, dynamic>>? tugas,
  }) : currentDate = currentDate ?? DateTime.now(),
       mataKuliah = mataKuliah ?? [],
       tugas = tugas ?? [];

  HomeModel copyWith({
    String? userName,
    String? userRole,
    bool? isLoading,
    DateTime? currentDate,
    List<Map<String, dynamic>>? mataKuliah,
    List<Map<String, dynamic>>? tugas,
  }) {
    return HomeModel(
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      isLoading: isLoading ?? this.isLoading,
      currentDate: currentDate ?? this.currentDate,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      tugas: tugas ?? this.tugas,
    );
  }

  bool get hasMataKuliah => mataKuliah.isNotEmpty;
  bool get hasTugas => tugas.isNotEmpty;
}
