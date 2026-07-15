import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.43.27:5000/api';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung ke server backend'};
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': 'user'}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung ke server'};
    }
  }

  static Future<Map<String, dynamic>> registerWithDetails({
    required String email,
    required String password,
    required String namaLengkap,
    required String kota,
    required String noTelepon,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nama_lengkap': namaLengkap,
          'kota': kota,
          'no_telepon': noTelepon,
          'role': 'user'
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung ke server'};
    }
  }

  static Future<Map<String, dynamic>> prediksiKNN({
    required int idPengguna,
    required double curahHujan,
    required double durasiJam,
    required int nilaiK,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_pengguna': idPengguna,
          'curah_hujan': curahHujan,
          'durasi_jam': durasiJam,
          'nilai_k': nilaiK,
          'lokasi_input': 'Stasiun Pemantau Mobile'
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi API terputus'};
    }
  }

  static Future<Map<String, dynamic>> getPredictHistory(int idPengguna) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/predict?id_pengguna=$idPengguna'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi API terputus'};
    }
  }

  static Future<Map<String, dynamic>> getDataLatih() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data-latih'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi API terputus'};
    }
  }
}