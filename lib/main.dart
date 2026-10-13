import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/academic_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/spp_provider.dart';
import 'providers/student_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();

  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(EBayyinahApp(initialAuthProvider: authProvider));
}

class EBayyinahApp extends StatelessWidget {
  final AuthProvider? initialAuthProvider;

  const EBayyinahApp({super.key, this.initialAuthProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (initialAuthProvider != null)
          ChangeNotifierProvider.value(value: initialAuthProvider!)
        else
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => SPPProvider()),
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'SIMS E-Bayyinah',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isAuthenticated
                ? const MainNavigationScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
