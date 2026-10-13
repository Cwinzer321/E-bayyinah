import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'dashboard/admin_dashboard_tab.dart';
import 'dashboard/alumni_dashboard_tab.dart';
import 'dashboard/student_dashboard_tab.dart';
import 'dashboard/teacher_dashboard_tab.dart';
import 'nilai/nilai_screen.dart';
import 'presensi/presensi_screen.dart';
import 'settings/settings_screen.dart';
import 'spp/spp_screen.dart';
import 'students/student_list_screen.dart';
import 'tracer/tracer_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final role = user?.role.toLowerCase() ?? 'admin';

    // Konfigurasi Tab Berdasarkan Peran Pengguna (FR-02)
    List<Widget> tabs = [];
    List<BottomNavigationBarItem> navItems = [];

    if (role == 'admin') {
      tabs = [
        const AdminDashboardTab(),
        const StudentListScreen(),
        const PresensiScreen(),
        const SPPScreen(),
        const SettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Siswa'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Presensi'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'SPP'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
      ];
    } else if (role == 'guru') {
      tabs = [
        const TeacherDashboardTab(),
        const StudentListScreen(),
        const PresensiScreen(),
        const NilaiScreen(),
        const SettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Siswa'),
        BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Presensi'),
        BottomNavigationBarItem(icon: Icon(Icons.edit_note_rounded), label: 'Nilai'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
      ];
    } else if (role == 'alumni') {
      tabs = [
        const AlumniDashboardTab(),
        const TracerScreen(initialTab: 0),
        const TracerScreen(initialTab: 1),
        const SettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: 'Alumni'),
        BottomNavigationBarItem(icon: Icon(Icons.work_outline_rounded), label: 'Tracer'),
        BottomNavigationBarItem(icon: Icon(Icons.verified_outlined), label: 'Legalisir'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
      ];
    } else {
      // Role: Siswa
      tabs = [
        const StudentDashboardTab(),
        const PresensiScreen(),
        const NilaiScreen(),
        const SPPScreen(),
        const SettingsScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Kartu Siswa'),
        BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Presensi'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'e-Rapor'),
        BottomNavigationBarItem(icon: Icon(Icons.payment_rounded), label: 'SPP'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
      ];
    }

    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-BAYYINAH SIMS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Portal ${user?.role ?? "Admin"} • ${user?.fullName ?? ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGoldLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold, width: 1),
            ),
            child: Text(
              user?.role.toUpperCase() ?? 'ADMIN',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: navItems,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
        ),
      ),
    );
  }
}
