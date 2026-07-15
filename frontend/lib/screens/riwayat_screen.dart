import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/other_services.dart';
import '../utils/app_theme.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  String? _filterLevel;
  final List<String?> _levels = [null, 'Sangat Tinggi', 'Tinggi', 'Sedang', 'Rendah'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionService>().loadRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final pred = context.watch<PredictionService>();
      final all  = pred.riwayatList;
      final auth = context.read<AuthService>();
      final idPengguna = auth.user?.idPengguna ?? 0;
      final filtered = _filterLevel == null
          ? all
          : all.where((r) => r['level_risiko'] == _filterLevel).toList();

      // Hitung statistik ringkas
      final total = all.length;
      final aktif = all.where((r) =>
          r['level_risiko'] == 'Tinggi' || r['level_risiko'] == 'Sangat Tinggi').length;
      final sangatTinggi = all.where((r) => r['level_risiko'] == 'Sangat Tinggi').length;
      final selesai = total - aktif;

      return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Riwayat Peringatan',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<PredictionService>().loadRiwayat(level: _filterLevel);
                        },
                        icon: const Icon(Icons.filter_list, size: 16, color: Colors.white),
                        label: const Text('Filter', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                  Text('$total kejadian tercatat',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _statBox('$total', 'Total Kejadian', AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('$aktif', 'Aktif', AppColors.tinggi)),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('$sangatTinggi', 'Sangat Tinggi', AppColors.sangatTinggi)),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('$selesai', 'Selesai', AppColors.rendah)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Level Risiko', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _levels.map((l) {
                        final selected = _filterLevel == l;
                        return ChoiceChip(
                          label: Text(l ?? 'Semua', style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => setState(() => _filterLevel = l),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFF0F4FF),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text('Belum ada riwayat prediksi',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Text('ID: $idPengguna, Data: ${all.length}, Filter: $_filterLevel',
                              style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildRiwayatItem(filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
      );
    } catch (e, stack) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Layar Riwayat Mengalami Error', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Error: $e\n\nStack:\n$stack',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _statBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  Widget _buildRiwayatItem(Map<String, dynamic> r) {
    try {
      final level = r['level_risiko'] as String? ?? 'Rendah';
      final color = risikoColor(level);
      final waktu = DateTime.tryParse(r['waktu_prediksi'] ?? '') ?? DateTime.now();
      
      String tanggal;
      try {
        tanggal = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(waktu);
      } catch (_) {
        tanggal = waktu.toString().split('.')[0];
      }

      final isAktif = level == 'Tinggi' || level == 'Sangat Tinggi';

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEFF)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(risikoIcon(level), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r['lokasi_input'] ?? 'Lokasi tidak diketahui',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                        child: Text(level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tanggal, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '${(r['curah_hujan'] as num?)?.toStringAsFixed(0) ?? '0'} mm/jam · '
                    '${(r['durasi_jam'] as num?)?.toStringAsFixed(1) ?? '0'} jam · K=${r['nilai_k'] ?? '-'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAktif ? AppColors.sangatTinggi.withOpacity(0.1) : AppColors.rendah.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAktif ? 'Aktif' : 'Selesai',
                      style: TextStyle(
                        fontSize: 10,
                        color: isAktif ? AppColors.sangatTinggi : AppColors.rendah,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          'Error item: $e',
          style: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      );
    }
  }
}