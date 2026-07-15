import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/other_services.dart';
import '../utils/app_theme.dart';
import 'prediksi_screen.dart';
import 'peta_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';
import 'notifikasi_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Muat data peta & notifikasi saat halaman pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetaService>().loadPeta();
      context.read<NotifikasiService>().loadNotifikasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final peta = context.watch<PetaService>();
    final notif = context.watch<NotifikasiService>();

    final titikTertinggi = peta.titikList.isNotEmpty
        ? peta.titikList.reduce((a, b) =>
            (a.risikoPct ?? 0) > (b.risikoPct ?? 0) ? a : b)
        : null;

    final namaHari = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<PetaService>().loadPeta();
          await context.read<NotifikasiService>().loadNotifikasi();
        },
        child: CustomScrollView(
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selamat Datang,',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                              Text(
                                auth.user?.namaLengkap ?? 'Pengguna',
                                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(namaHari, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Notifikasi icon
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                            if (notif.unread > 0)
                              Positioned(
                                right: 6, top: 6,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                ),
                              ),
                          ],
                        ),
                        // Logout icon
                        IconButton(
                          onPressed: () => _showLogoutDialog(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          tooltip: 'Keluar',
                        ),
                        const SizedBox(width: 4),
                        // Avatar
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProfilScreen())),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(auth.user?.initials ?? '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- KONTEN ----------------
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusRisiko(titikTertinggi),
                  const SizedBox(height: 16),
                  _buildMiniStats(titikTertinggi),
                  const SizedBox(height: 16),
                  _buildGrafikCurahHujan(),
                  const SizedBox(height: 16),
                  _buildAksesCepat(context),
                  const SizedBox(height: 16),
                  _buildPeringatanAktif(peta),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // CARD: Status Risiko Saat Ini (lingkaran persentase)
  // -------------------------------------------------------
  Widget _buildStatusRisiko(dynamic titik) {
    final level = titik?.namaStatus ?? 'Rendah';
    final pct   = titik?.risikoPct ?? 0.0;
    final color = risikoColor(level);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(risikoIcon(level), size: 16, color: color),
                    const SizedBox(width: 6),
                    Text('Status Risiko Saat Ini',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(level.toUpperCase(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 8),
                if (titik != null)
                  Text(titik.namaLokasi,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Lingkaran persentase
          SizedBox(
            width: 64, height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFF0F4FF),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // MINI STATS: Curah hujan, durasi, kecepatan angin
  // -------------------------------------------------------
  Widget _buildMiniStats(dynamic titik) {
    final curah  = titik?.curahHujan ?? 0.0;
    final durasi = titik?.durasiJam ?? 0.0;

    return Row(
      children: [
        Expanded(child: _miniStatCard(Icons.water_drop_outlined,
            '${curah.toStringAsFixed(0)} mm', 'Curah Hujan', AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _miniStatCard(Icons.timer_outlined,
            '${durasi.toStringAsFixed(1)} Jam', 'Durasi Hujan', AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _miniStatCard(Icons.air,
            '24 km/h', 'Kecepatan Angin', AppColors.tinggi)),
      ],
    );
  }

  Widget _miniStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEFF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // GRAFIK CURAH HUJAN (line chart 7 hari)
  // -------------------------------------------------------
  Widget _buildGrafikCurahHujan() {
    // Data dummy 7 hari (bisa diganti dari API riwayat agregasi)
    final spots = [22.0, 28.0, 18.0, 35.0, 42.0, 60.0, 45.0];
    final hari  = ['Sn','Sl','Rb','Km','Jm','Sb','Mg'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Grafik Curah Hujan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const Text('7 hari', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= hari.length) return const SizedBox();
                        return Text(hari[i], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(spots.length, (i) => FlSpot(i.toDouble(), spots[i])),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // AKSES CEPAT (2 tombol besar: Prediksi K-NN, Pantau Peta)
  // -------------------------------------------------------
  Widget _buildAksesCepat(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickButton(
                icon: Icons.bar_chart,
                title: 'Prediksi K-NN',
                subtitle: 'Hitung risiko banjir',
                gradient: AppColors.prediksiGradient,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrediksiScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickButton(
                icon: Icons.map,
                title: 'Pantau Peta',
                subtitle: 'Lihat titik banjir',
                gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)]),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PetaScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _quickButton(
          icon: Icons.history,
          title: 'Riwayat',
          subtitle: 'Lihat riwayat peringatan',
          gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7C4DFF)]),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RiwayatScreen())),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // PERINGATAN AKTIF (daftar titik risiko tinggi)
  // -------------------------------------------------------
  Widget _buildPeringatanAktif(PetaService peta) {
    final aktif = peta.titikList
        .where((t) => t.namaStatus == 'Tinggi' || t.namaStatus == 'Sangat Tinggi')
        .toList()
      ..sort((a, b) => (b.risikoPct ?? 0).compareTo(a.risikoPct ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Peringatan Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PetaScreen())),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (aktif.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Tidak ada peringatan aktif saat ini',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            )
          else
            ...aktif.take(3).map((t) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: risikoColor(t.namaStatus), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.namaLokasi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${t.curahHujan?.toStringAsFixed(0) ?? '-'} mm/jam',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: risikoColor(t.namaStatus).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(t.namaStatus ?? '',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: risikoColor(t.namaStatus))),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.sangatTinggi.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout, color: AppColors.sangatTinggi, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Keluar dari Aplikasi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Anda akan keluar dari sesi saat ini', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.sangatTinggi),
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}