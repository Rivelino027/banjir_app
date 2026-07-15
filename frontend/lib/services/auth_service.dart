import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // 1. Cek sesi login saat aplikasi dibuka
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('id_pengguna');
      final email = prefs.getString('email');
      final role = prefs.getString('role');
      final namaLengkap = prefs.getString('nama_lengkap');
      final kota = prefs.getString('kota');
      final noTelepon = prefs.getString('no_telepon');

      if (id != null && email != null && role != null) {
        _user = UserModel(
          idPengguna: id,
          email: email,
          role: role,
          namaLengkap: namaLengkap ?? 'Pengguna',
          kota: kota ?? '',
          noTelepon: noTelepon ?? '',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error checking session: $e");
    }
    return false;
  }

  // 2. Login User / Admin
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Mode Demo Offline Fallback
    if (email.contains('demo') || email == 'admin@sipebanjir.id') {
      await Future.delayed(const Duration(milliseconds: 800));
      _user = UserModel(
        idPengguna: email == 'admin@sipebanjir.id' ? 1 : 2,
        email: email,
        role: email == 'admin@sipebanjir.id' ? 'admin' : 'user',
        namaLengkap: email == 'admin@sipebanjir.id' ? 'Admin Sistem' : 'Demo User',
        kota: 'Kota Padang',
        noTelepon: '081234567890',
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('id_pengguna', _user!.idPengguna);
      await prefs.setString('email', _user!.email);
      await prefs.setString('role', _user!.role);
      await prefs.setString('nama_lengkap', _user!.namaLengkap);
      await prefs.setString('kota', _user!.kota);
      await prefs.setString('no_telepon', _user!.noTelepon);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Panggil API Backend
    final res = await ApiService.login(email, password);
    _isLoading = false;

    if (res['status'] == 'success') {
      final data = res['data'];
      _user = UserModel.fromJson(data);

      // Simpan di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('id_pengguna', _user!.idPengguna);
      await prefs.setString('email', _user!.email);
      await prefs.setString('role', _user!.role);
      await prefs.setString('nama_lengkap', _user!.namaLengkap);
      await prefs.setString('kota', _user!.kota);
      await prefs.setString('no_telepon', _user!.noTelepon);

      notifyListeners();
      return true;
    } else {
      _error = res['message'] ?? 'Kredensial salah';
      notifyListeners();
      return false;
    }
  }

  // 3. Registrasi User Baru
  Future<bool> register({
    required String namaLengkap,
    required String email,
    required String password,
    required String kota,
    required String noTelepon,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Buat API request map (kita akan update ApiService untuk ini)
    final res = await ApiService.registerWithDetails(
      email: email,
      password: password,
      namaLengkap: namaLengkap,
      kota: kota,
      noTelepon: noTelepon,
    );
    
    _isLoading = false;

    if (res['status'] == 'success') {
      notifyListeners();
      return true;
    } else {
      _error = res['message'] ?? 'Gagal melakukan registrasi';
      notifyListeners();
      return false;
    }
  }

  // 4. Logout Sesi
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
