/// Status akademik pengguna. Disimpan sebagai String biasa di Firestore
/// (bukan enum) supaya konsisten dengan pola TaskSubjects — fleksibel dan
/// gampang dibaca langsung dari dokumen tanpa mapping tambahan.
class UserStatus {
  UserStatus._();

  static const String mahasiswa = 'Mahasiswa';
  static const String pelajar = 'Pelajar';
  static const String umum = 'Umum';

  static const List<String> options = [mahasiswa, pelajar, umum];
}

class UserGender {
  UserGender._();

  static const String male = 'Laki-laki';
  static const String female = 'Perempuan';

  static const List<String> options = [male, female];
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;

  // --- Profil tambahan (Informasi Pribadi & Akademik di Edit Profil) ---
  final String? gender;
  final DateTime? birthDate;

  /// Status pengguna: 'Mahasiswa' / 'Pelajar' / 'Umum'. Menentukan apakah
  /// field [semester] relevan ditampilkan di UI.
  final String? status;

  /// Hanya bermakna kalau [status] == [UserStatus.mahasiswa]. Disimpan tetap
  /// sebagai field terpisah (bukan dihitung) supaya tidak hilang kalau user
  /// sempat ganti status lalu ganti balik.
  final int? semester;

  final String? phone;
  final String? address;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.gender,
    this.birthDate,
    this.status,
    this.semester,
    this.phone,
    this.address,
  });

  /// Umur dihitung dari [birthDate] terhadap tanggal hari ini. Null kalau
  /// user belum pernah mengisi tanggal lahir.
  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final birthdayPassedThisYear = (now.month > birth.month) ||
        (now.month == birth.month && now.day >= birth.day);
    if (!birthdayPassedThisYear) years--;
    return years;
  }

  bool get isMahasiswa => status == UserStatus.mahasiswa;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Field numerik lewat FirestoreRestClient kadang datang sebagai num
    // (bukan int murni), jadi selalu di-cast lewat num? lalu .toInt().
    final rawSemester = map['semester'];
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      gender: map['gender'] as String?,
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'] as String)
          : null,
      status: map['status'] as String?,
      semester: rawSemester is num ? rawSemester.toInt() : null,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'status': status,
      'semester': semester,
      'phone': phone,
      'address': address,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? gender,
    DateTime? birthDate,
    String? status,
    int? semester,
    String? phone,
    String? address,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      status: status ?? this.status,
      semester: semester ?? this.semester,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  /// Salinan dengan semester dikosongkan — dipakai saat status diganti
  /// menjadi bukan Mahasiswa, supaya data semester lama tidak "menempel"
  /// diam-diam di Firestore.
  UserModel clearSemester() {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: createdAt,
      gender: gender,
      birthDate: birthDate,
      status: status,
      semester: null,
      phone: phone,
      address: address,
    );
  }
}
