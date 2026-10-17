import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'survey_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String _nama = 'Pengguna';
  int _jumlahSurvey = 0;
  String? _error;

  // Definisi Warna Hijau Tua
  final Color primaryGreen = const Color(0xFF00695C); // Hijau Tua (Teal 800)
  final Color primaryGreenLight = const Color(0xFFE0F2F1); // Hijau Sangat Pucat untuk Avatar Menu
  final Color backgroundColor = const Color(0xFFF4F8F6); // Background hijau clean

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final result = await ApiService.getDashboard();
      final data = ApiService.unwrap(result);

      if (data is Map) {
        final user = data['user'] ?? data['profile'];

        setState(() {
          if (user is Map) {
            _nama = (user['name'] ??
                    user['nama'] ??
                    user['username'] ??
                    'Pengguna')
                .toString();
          }

          final jumlah = data['total_surveys'] ??
              data['survey_count'] ??
              data['jumlah_survey'] ??
              data['totalSurvey'];

          _jumlahSurvey = int.tryParse('$jumlah') ?? 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    try {
      await ApiService.logout();
    } catch (_) {
      // Token tetap dihapus oleh ApiService.logout().
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: primaryGreenLight,
          child: Icon(icon, color: primaryGreen, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: primaryGreen),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard Survey'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: primaryGreen,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Banner Profil
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Total Survey
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      size: 40,
                      color: primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Survey'),
                          const SizedBox(height: 6),
                          if (_loading)
                            SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryGreen,
                              ),
                            )
                          else
                            Text(
                              '$_jumlahSurvey',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dashboard belum dapat dimuat: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Menu Data Survey
            _menuCard(
              icon: Icons.assignment,
              title: 'Data Survey',
              description: 'Lihat, tambah, edit, dan hapus data survey.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyScreen(),
                  ),
                );
              },
            ),

            // Menu Profil Saya
            _menuCard(
              icon: Icons.person_outline,
              title: 'Profil Saya',
              description: 'Lihat dan ubah informasi akun.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}