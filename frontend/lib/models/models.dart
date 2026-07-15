class UserModel {
  final int idPengguna;
  final String email;
  final String role;
  final String namaLengkap;
  final String kota;
  final String noTelepon;

  UserModel({
    required this.idPengguna,
    required this.email,
    required this.role,
    required this.namaLengkap,
    required this.kota,
    required this.noTelepon,
  });

  String get initials {
    final name = namaLengkap.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idPengguna: json['id_pengguna'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      namaLengkap: json['nama_lengkap'] ?? json['namaLengkap'] ?? 'Pengguna',
      kota: json['kota'] ?? '',
      noTelepon: json['no_telepon'] ?? json['noTelepon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pengguna': idPengguna,
      'email': email,
      'role': role,
      'nama_lengkap': namaLengkap,
      'kota': kota,
      'no_telepon': noTelepon,
    };
  }
}

class PetaModel {
  final int idData;
  final String wilayah;
  final double curahHujan;
  final double durasiJam;
  final int idLabel;
  final double risikoPct;
  final double latitude;
  final double longitude;
  final String sumber;
  final String namaStatus;
  final String kodeWarna;

  PetaModel({
    required this.idData,
    required this.wilayah,
    required this.curahHujan,
    required this.durasiJam,
    required this.idLabel,
    required this.risikoPct,
    required this.latitude,
    required this.longitude,
    required this.sumber,
    required this.namaStatus,
    required this.kodeWarna,
  });

  String get namaLokasi => wilayah;

  factory PetaModel.fromJson(Map<String, dynamic> json) {
    return PetaModel(
      idData: json['id_data'] ?? 0,
      wilayah: json['wilayah'] ?? '',
      curahHujan: (json['curah_hujan'] as num?)?.toDouble() ?? 0.0,
      durasiJam: (json['durasi_jam'] as num?)?.toDouble() ?? 0.0,
      idLabel: json['id_label'] ?? 1,
      risikoPct: (json['risiko_pct'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      sumber: json['sumber'] ?? '',
      namaStatus: json['nama_status'] ?? 'Rendah',
      kodeWarna: json['kode_warna'] ?? '#22C55E',
    );
  }
}

class NotifikasiModel {
  final String idNotifikasi;
  final String judul;
  final String pesan;
  final String namaStatus;
  bool belumDibaca;
  final DateTime createdAt;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.judul,
    required this.pesan,
    required this.namaStatus,
    required this.belumDibaca,
    required this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? json['id'] ?? '',
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      namaStatus: json['nama_status'] ?? 'Rendah',
      belumDibaca: json['belum_dibaca'] ?? json['unread'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
