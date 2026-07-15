import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/other_services.dart';
import '../utils/app_theme.dart';

class PrediksiScreen extends StatefulWidget {
  const PrediksiScreen({super.key});

  @override
  State<PrediksiScreen> createState() => _PrediksiScreenState();
}

class _PrediksiScreenState extends State<PrediksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hujanCtrl = TextEditingController();
  final _durasiCtrl = TextEditingController();
  int _selectedK = 5; // Default K=5

  @override
  void dispose() {
    _hujanCtrl.dispose();
    _durasiCtrl.dispose();
    super.dispose();
  }

  void _runPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    final curahHujan = double.tryParse(_hujanCtrl.text) ?? 0.0;
    final durasiHujan = double.tryParse(_durasiCtrl.text) ?? 0.0;

    final predService = context.read<PredictionService>();
    final hasil = await predService.hitungKNN(
      curahHujan: curahHujan,
      durasiJam: durasiHujan,
      nilaiK: _selectedK,
    );

    if (!mounted) return;

    if (hasil != null) {
      _showResultBottomSheet(hasil);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghitung prediksi. Silakan coba lagi.')),
      );
    }
  }

  void _showResultBottomSheet(Map<String, dynamic> hasil) {
    final status = hasil['nama_status'] as String? ?? 'Rendah';
    final deskripsi = hasil['deskripsi'] as String? ?? '';
    final color = risikoColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(risikoIcon(status), color: color, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Prediksi Klasifikasi',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                deskripsi,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pred = context.watch<PredictionService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------------- HEADER ----------------
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bar_chart, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Prediksi K-NN',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'K-Nearest Neighbor Algorithm',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- FORM ----------------
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Algoritma Info Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Algoritma K-NN',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sistem mengklasifikasikan risiko banjir berdasarkan kedekatan dengan data latih menggunakan jarak Euclidean pada parameter curah hujan dan durasi.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue[900], height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inputs Title
                    const Text(
                      'Input Parameter',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),

                    // Curah Hujan
                    const Text('Curah Hujan (mm/jam)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _hujanCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 62',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Curah hujan wajib diisi';
                        if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Durasi Hujan
                    const Text('Durasi Hujan (jam)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _durasiCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 4.5',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Durasi hujan wajib diisi';
                        if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Nilai K
                    const Text('Nilai K (Jumlah Tetangga)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [3, 5, 7].map((k) {
                        final isSelected = _selectedK == k;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('K = $k', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedK = k),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Run Button
                    ElevatedButton.icon(
                      onPressed: pred.isLoading ? null : _runPrediction,
                      icon: pred.isLoading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow, size: 18),
                      label: Text(pred.isLoading ? 'Sedang Memproses...' : 'Jalankan Prediksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}