import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'services/auth_service.dart';
import 'services/other_services.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal lokal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Kunci orientasi ke portrait saja
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SiPeBanjirApp());
}

class SiPeBanjirApp extends StatelessWidget {
  const SiPeBanjirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PredictionService()),
        ChangeNotifierProvider(create: (_) => NotifikasiService()),
        ChangeNotifierProvider(create: (_) => PetaService()),
      ],
      child: MaterialApp(
        title: 'SiPeBanjir',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}