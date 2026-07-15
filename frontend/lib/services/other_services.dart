import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../api_service.dart';

// 1. PETA SERVICE (MANAJEMEN DATA LATIH & TITIK RAWAN)
class PetaService extends ChangeNotifier {
  List<PetaModel> _titikList = [];
  bool _isLoading = false;

  List<PetaModel> get titikList => _titikList;
  bool get isLoading => _isLoading;

  Future<void> loadPeta({String? level}) async {
    _isLoading = true;
    notifyListeners();

    // Fallback data offline jika API tidak terhubung
    final fallbackList = [
      PetaModel(idData: 1, wilayah: 'Jl. Gatot Subroto', curahHujan: 62, durasiJam: 4.5, idLabel: 4, risikoPct: 95, latitude: -0.2088, longitude: 100.8456, sumber: 'BMKG', namaStatus: 'Sangat Tinggi', kodeWarna: '#EF4444'),
      PetaModel(idData: 2, wilayah: 'Kawasan Pasar Baru', curahHujan: 45, durasiJam: 3.2, idLabel: 3, risikoPct: 75, latitude: -0.1974, longitude: 100.8358, sumber: 'BMKG', namaStatus: 'Tinggi', kodeWarna: '#F97316'),
      PetaModel(idData: 3, wilayah: 'Perumahan Griya Mas', curahHujan: 28, durasiJam: 2.0, idLabel: 2, risikoPct: 52, latitude: -0.1751, longitude: 100.8658, sumber: 'Sintetik', namaStatus: 'Sedang', kodeWarna: '#EAB308'),
      PetaModel(idData: 4, wilayah: 'JL. Diponegoro', curahHujan: 12, durasiJam: 1.0, idLabel: 1, risikoPct: 23, latitude: -0.1925, longitude: 100.8227, sumber: 'Sintetik', namaStatus: 'Rendah', kodeWarna: '#22C55E'),
      PetaModel(idData: 5, wilayah: 'Terminal Kota', curahHujan: 38, durasiJam: 2.8, idLabel: 3, risikoPct: 68, latitude: -0.1844, longitude: 100.8466, sumber: 'BMKG', namaStatus: 'Tinggi', kodeWarna: '#F97316'),
      PetaModel(idData: 6, wilayah: 'Komplek Ruko Selatan', curahHujan: 22, durasiJam: 1.5, idLabel: 2, risikoPct: 45, latitude: -0.2100, longitude: 100.8500, sumber: 'Sintetik', namaStatus: 'Sedang', kodeWarna: '#EAB308'),
      PetaModel(idData: 7, wilayah: 'Jl. Ahmad Yani', curahHujan: 8, durasiJam: 0.8, idLabel: 1, risikoPct: 15, latitude: -0.1800, longitude: 100.8200, sumber: 'BMKG', namaStatus: 'Rendah', kodeWarna: '#22C55E'),
    ];

    final res = await ApiService.getDataLatih();
    _isLoading = false;

    if (res['status'] == 'success' && res['data'] != null) {
      final List rawData = res['data'];
      _titikList = rawData.map((e) => PetaModel.fromJson(e)).toList();
    } else {
      _titikList = fallbackList;
    }

    if (level != null) {
      _titikList = _titikList.where((element) => element.namaStatus == level).toList();
    }

    notifyListeners();
  }
}

// 2. NOTIFIKASI SERVICE (PERINGATAN DINI REAL-TIME)
class NotifikasiService extends ChangeNotifier {
  List<NotifikasiModel> _list = [];
  bool _isLoading = false;

  List<NotifikasiModel> get list => _list;
  bool get isLoading => _isLoading;
  int get unread => _list.where((n) => n.belumDibaca).length;

  Future<void> loadNotifikasi() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    
    // Seed dummy notifications data matching layout page 2 of PDF
    if (_list.isEmpty) {
      _list = [
        NotifikasiModel(
          idNotifikasi: '1',
          judul: 'Peringatan Merah — Banjir Tinggi',
          pesan: 'Jl. Gatot Subroto: Curah hujan 62mm/jam, durasi 4.5 jam. Risiko banjir SANGAT TINGGI (95%). Harap waspada!',
          namaStatus: 'Sangat Tinggi',
          belumDibaca: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        NotifikasiModel(
          idNotifikasi: '2',
          judul: 'Peringatan Oranye — Potensi Banjir',
          pesan: 'Kawasan Pasar Baru: Curah hujan 45mm/jam, durasi 3.2 jam. Tingkat risiko TINGGI (75%). Siapkan langkah antisipasi.',
          namaStatus: 'Tinggi',
          belumDibaca: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotifikasiModel(
          idNotifikasi: '3',
          judul: 'Peringatan Kuning — Pantau Cuaca',
          pesan: 'Perumahan Griya Mas: Curah hujan 28mm/jam, durasi 2 jam. Risiko SEDANG (52%). Pantau perkembangan.',
          namaStatus: 'Sedang',
          belumDibaca: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        NotifikasiModel(
          idNotifikasi: '4',
          judul: 'Status Normal — Jl. Ahmad Yani',
          pesan: 'Jl. Ahmad Yani: Hujan mereda. Curah hujan 8mm/jam. Risiko RENDAH (15%). Kondisi aman.',
          namaStatus: 'Rendah',
          belumDibaca: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  void tandaiBaca(String id) {
    final idx = _list.indexWhere((n) => n.idNotifikasi == id);
    if (idx != -01 && idx < _list.length) {
      _list[idx].belumDibaca = false;
      notifyListeners();
    }
  }

  void bacaSemua() {
    for (var n in _list) {
      n.belumDibaca = false;
    }
    notifyListeners();
  }
}

// 3. PREDIKSI SERVICE (ALGORITMA K-NN RUNNER & RIWAYAT)
class PredictionService extends ChangeNotifier {
  List<Map<String, dynamic>> _riwayatList = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get riwayatList => _riwayatList;
  bool get isLoading => _isLoading;

  Future<void> loadRiwayat({String? level}) async {
    _isLoading = true;
    notifyListeners();

    // Fallback data demo jika backend belum jalan / offline
    final List<Map<String, dynamic>> fallbackRiwayat = [
      {
        'id_prediksi': 1,
        'curah_hujan': 62.0,
        'durasi_jam': 4.5,
        'nilai_k': 5,
        'level_risiko': 'Sangat Tinggi',
        'waktu_prediksi': DateTime.now().subtract(const Duration(minutes: 15)).toIsoformatString(),
        'lokasi_input': 'Jl. Gatot Subroto',
      },
      {
        'id_prediksi': 2,
        'curah_hujan': 45.0,
        'durasi_jam': 3.2,
        'nilai_k': 5,
        'level_risiko': 'Tinggi',
        'waktu_prediksi': DateTime.now().subtract(const Duration(hours: 2, minutes: 30)).toIsoformatString(),
        'lokasi_input': 'Kawasan Pasar Baru',
      },
      {
        'id_prediksi': 3,
        'curah_hujan': 30.0,
        'durasi_jam': 2.0,
        'nilai_k': 3,
        'level_risiko': 'Sedang',
        'waktu_prediksi': DateTime.now().subtract(const Duration(days: 1, hours: 4)).toIsoformatString(),
        'lokasi_input': 'Jl. Ahmad Yani',
      },
      {
        'id_prediksi': 4,
        'curah_hujan': 38.0,
        'durasi_jam': 2.8,
        'nilai_k': 5,
        'level_risiko': 'Tinggi',
        'waktu_prediksi': DateTime.now().subtract(const Duration(days: 1, hours: 8)).toIsoformatString(),
        'lokasi_input': 'Terminal Kota',
      },
    ];

    try {
      final prefs = await SharedPreferences.getInstance();
      final idPengguna = prefs.getInt('id_pengguna') ?? 0;
      
      // Jika demo account, pakai demo history
      if (idPengguna == 1 || idPengguna == 2) {
        _riwayatList = fallbackRiwayat;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await ApiService.getPredictHistory(idPengguna);
      if (res['status'] == 'success' && res['data'] != null) {
        final List data = res['data'];
        if (data.isNotEmpty) {
          _riwayatList = List<Map<String, dynamic>>.from(data);
        } else {
          _riwayatList = fallbackRiwayat;
        }
      } else {
        _riwayatList = fallbackRiwayat;
      }
    } catch (e) {
      debugPrint("Error loading riwayat: $e");
      _riwayatList = fallbackRiwayat;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> hitungKNN({
    required double curahHujan,
    required double durasiJam,
    required int nilaiK,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final idPengguna = prefs.getInt('id_pengguna') ?? 0;

      // Mode Demo Offline Fallback
      if (idPengguna == 1 || idPengguna == 2 || idPengguna == 0) {
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Buat kalkulasi murni sederhana untuk demo
        String status = 'Rendah';
        String warna = '#22C55E';
        String deskripsi = 'Kondisi aman, curah hujan dan durasi rendah.';
        
        double metric = curahHujan * durasiJam;
        if (metric > 200) {
          status = 'Sangat Tinggi';
          warna = '#EF4444';
          deskripsi = 'Kondisi evakuasi, risiko banjir bandang tinggi.';
        } else if (metric > 120) {
          status = 'Tinggi';
          warna = '#F97316';
          deskripsi = 'Kondisi siaga, potensi banjir di area rawan.';
        } else if (metric > 50) {
          status = 'Sedang';
          warna = '#EAB308';
          deskripsi = 'Kondisi waspada, potensi genangan air di beberapa titik.';
        }

        final result = {
          'id_label': status == 'Sangat Tinggi' ? 4 : (status == 'Tinggi' ? 3 : (status == 'Sedang' ? 2 : 1)),
          'nama_status': status,
          'kode_warna': warna,
          'deskripsi': deskripsi
        };

        // Simpan ke riwayat lokal
        _riwayatList.insert(0, {
          'id_prediksi': DateTime.now().millisecondsSinceEpoch,
          'curah_hujan': curahHujan,
          'durasi_jam': durasiJam,
          'nilai_k': nilaiK,
          'level_risiko': status,
          'waktu_prediksi': DateTime.now().toIsoformatString(),
          'lokasi_input': 'Stasiun Pemantau Mobile',
        });

        _isLoading = false;
        notifyListeners();
        return result;
      }

      final res = await ApiService.prediksiKNN(
        idPengguna: idPengguna,
        curahHujan: curahHujan,
        durasiJam: durasiJam,
        nilaiK: nilaiK,
      );

      _isLoading = false;
      if (res['status'] == 'success' && res['result'] != null) {
        await loadRiwayat();
        return Map<String, dynamic>.from(res['result']);
      }
    } catch (e) {
      debugPrint("Error performing prediction: $e");
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }
}

// Helper extension untuk format ISO string
extension DateTimeIso on DateTime {
  String toIsoformatString() {
    return toIso8601String();
  }
}
