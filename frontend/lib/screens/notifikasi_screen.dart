import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/other_services.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'profil_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  bool _hanyaBelumDibaca = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifikasiService>().loadNotifikasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotifikasiService>();
    final list = _hanyaBelumDibaca
        ? notif.list.where((n) => n.belumDibaca).toList()
        : notif.list;

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
                      const Icon(Icons.notifications_active, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Notifikasi',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () => context.read<NotifikasiService>().bacaSemua(),
                        child: const Text('Tandai Semua', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  Text('${notif.unread} belum dibaca',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _tabButton('Semua (${notif.list.length})', !_hanyaBelumDibaca,
                            () => setState(() => _hanyaBelumDibaca = false)),
                        _tabButton('Belum Dibaca (${notif.unread})', _hanyaBelumDibaca,
                            () => setState(() => _hanyaBelumDibaca = true)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: notif.isLoading
                ? const SliverToBoxAdapter(child: Center(child: Padding(
                    padding: EdgeInsets.all(40), child: CircularProgressIndicator())))
                : list.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              const Text('Tidak ada notifikasi', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildNotifItem(list[i]),
                          childCount: list.length,
                        ),
                      ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifikasi Aktif',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Sistem akan mengirim peringatan otomatis setiap kali level risiko banjir berubah.',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: AppColors.sangatTinggi, size: 18),
                    label: const Text('Keluar', style: TextStyle(color: AppColors.sangatTinggi)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      side: const BorderSide(color: AppColors.sangatTinggi),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfilScreen())),
                    child: const Text('Lihat Profil Saya'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : Colors.white,
          )),
        ),
      ),
    );
  }

  Widget _buildNotifItem(NotifikasiModel n) {
    final color = risikoColor(n.namaStatus);
    final waktu = DateFormat('HH:mm, d MMM', 'id_ID').format(n.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.belumDibaca ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: n.belumDibaca ? color.withOpacity(0.3) : const Color(0xFFE8EEFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(risikoIcon(n.namaStatus), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.judul,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    if (n.belumDibaca)
                      Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.pesan, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(waktu, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    const SizedBox(width: 12),
                    if (n.belumDibaca)
                      GestureDetector(
                        onTap: () => context.read<NotifikasiService>().tandaiBaca(n.idNotifikasi),
                        child: const Text('Tandai Dibaca',
                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
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