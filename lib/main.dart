import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/contractor_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/report_summary_screen.dart';
import 'screens/admin/productivity_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContractorProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'TM Contractor Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/report_summary': (context) => const ReportSummaryScreen(),
          '/productivity': (context) => const ProductivityScreen(),
        },
      ),
    );
  }
}
