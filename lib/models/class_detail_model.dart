import '../services/postingan_service.dart';

class ClassDetailModel {
  List<Postingan> postinganList;
  bool isLoading;
  String errorMessage;
  String namaDosen;
  String userRole;
  String userName;

  ClassDetailModel({
    List<Postingan>? postinganList,
    this.isLoading = true,
    this.errorMessage = '',
    this.namaDosen = '',
    this.userRole = 'mahasiswa',
    this.userName = 'User',
  }) : postinganList = postinganList ?? [];

  ClassDetailModel copyWith({
    List<Postingan>? postinganList,
    bool? isLoading,
    String? errorMessage,
    String? namaDosen,
    String? userRole,
    String? userName,
  }) {
    return ClassDetailModel(
      postinganList: postinganList ?? this.postinganList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      namaDosen: namaDosen ?? this.namaDosen,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
    );
  }

  bool get hasError => errorMessage.isNotEmpty;
  bool get isEmpty => postinganList.isEmpty;
  bool get isDosen => userRole == 'dosen';
  bool get canCreatePostingan => isDosen;
  bool get canDeletePostingan => isDosen;
  String get roleDisplay => isDosen ? 'pengajar' : 'mahasiswa';
  String get emptyTitle => isDosen ? "Belum ada pengumuman" : "Belum ada pengumuman untuk kelas ini";
  String get emptyDescription => isDosen
      ? "Buat pengumuman pertama untuk menginformasikan hal penting kepada mahasiswa"
      : "Dosen akan memposting pengumuman penting di sini";
  String get sectionTitle => isDosen ? "Kelola Pengumuman" : "Pengumuman Kelas";
  String get dosenInfo => isDosen ? 'Anda adalah pengajar' : 'Dosen: $namaDosen';
}