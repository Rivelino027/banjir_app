import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/other_services.dart';
import '../utils/app_theme.dart';

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  String? _filterLevel; // null = Semua

  final List<String?> _filters = [null, 'Sangat Tinggi', 'Tinggi', 'Sedang', 'Rendah'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetaService>().loadPeta();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petaService = context.watch<PetaService>();
    final allTitik = petaService.titikList;
    final filtered = _filterLevel == null
        ? allTitik
        : allTitik.where((t) => t.namaStatus == _filterLevel).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------------- HEADER ----------------
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Peta Titik Banjir',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.read<PetaService>().loadPeta(level: _filterLevel),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  Text('${allTitik.length} titik terdeteksi',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 12),

                  // Search bar (visual only)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, size: 18, color: AppColors.textHint),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Cari lokasi...', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter chips
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filters.map((f) {
                        final selected = _filterLevel == f;
                        final label = f ?? 'Semua';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label, style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _filterLevel = f);
                              context.read<PetaService>().loadPeta(level: f);
                            },
                            selectedColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: selected ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            side: BorderSide.none,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- PETA ----------------
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEFF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: filtered.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(filtered.first.latitude, filtered.first.longitude),
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.sipebanjir.app',
                        ),
                        MarkerLayer(
                          markers: filtered.map((t) => Marker(
                            point: LatLng(t.latitude, t.longitude),
                            width: 36, height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: risikoColor(t.namaStatus),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(color: risikoColor(t.namaStatus).withOpacity(0.4), blurRadius: 8),
                                ],
                              ),
                              child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
            ),
          ),

          // ---------------- LEGENDA ----------------
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
                    const Text('Keterangan Level Risiko',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16, runSpacing: 8,
                      children: [
                        _legendItem(AppColors.sangatTinggi, 'Sangat Tinggi (> 80%)'),
                        _legendItem(AppColors.tinggi, 'Tinggi (60-80%)'),
                        _legendItem(AppColors.sedang, 'Sedang (40-60%)'),
                        _legendItem(AppColors.rendah, 'Rendah (< 40%)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------- DAFTAR TITIK RAWAN ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('Daftar Titik Rawan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                ...filtered.map((t) => _buildTitikItem(t)),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Tidak ada titik dengan level ini',
                        style: TextStyle(color: AppColors.textSecondary))),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTitikItem(PetaModel t) {
    final color = risikoColor(t.namaStatus);
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
            child: Icon(Icons.location_on_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.namaLokasi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${t.curahHujan?.toStringAsFixed(0) ?? '-'} mm/jam · ${t.durasiJam?.toStringAsFixed(1) ?? '-'} jam',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
            child: Text(t.namaStatus ?? '-', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}