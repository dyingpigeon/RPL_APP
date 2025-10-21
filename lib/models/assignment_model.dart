class AssignmentModel {
  Map<String, dynamic>? assignmentDetail;
  Map<String, dynamic>? submissionStatus;
  Map<String, dynamic>? userData;
  bool isLoading;
  bool isSubmitting;
  String errorMessage;
  String userRole;

  AssignmentModel({
    this.assignmentDetail,
    this.submissionStatus,
    this.userData,
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage = '',
    this.userRole = 'mahasiswa',
  });

  AssignmentModel copyWith({
    Map<String, dynamic>? assignmentDetail,
    Map<String, dynamic>? submissionStatus,
    Map<String, dynamic>? userData,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? userRole,
  }) {
    return AssignmentModel(
      assignmentDetail: assignmentDetail ?? this.assignmentDetail,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      userRole: userRole ?? this.userRole,
    );
  }

  bool get hasError => errorMessage.isNotEmpty;
  bool get isMahasiswa => userRole == 'mahasiswa';
  bool get isDosen => userRole == 'dosen';
  bool get isSubmitted => submissionStatus?['submitted'] ?? false;
  bool get canSubmit => isMahasiswa && !isSubmitted && !isSubmitting;
  String get judul => assignmentDetail?['judul'] ?? '';
  String get deadline => assignmentDetail?['deadline'] ?? '';
  String get deskripsi => assignmentDetail?['deskripsi'] ?? '';
  String get dosenNama => assignmentDetail?['dosenNama'] ?? '';
  String get userName => userData?['name'] ?? 'User';
  String get userNim => userData?['nim'] ?? '-';
  String get userKelas => userData?['kelas'] ?? '-';
  String get userProdi => userData?['prodi'] ?? '-';
  String get userNip => userData?['nip'] ?? '-';
  String get mataKuliah => assignmentDetail?['mataKuliah'] ?? '-';
  String get kelas => assignmentDetail?['kelas'] ?? '-';
  String get prodi => assignmentDetail?['prodi'] ?? '-';
  String get semester => assignmentDetail?['semester'] ?? '-';
  String? get fileUrl => assignmentDetail?['fileUrl'];
}