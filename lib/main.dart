import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/demo_config.dart';
import 'config/supabase_config.dart';
import 'providers/app_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Initialize Supabase if credentials are provided in .env (bypassed in Demo Mode)
  if (DemoConfig.isDemoMode) {
    debugPrint('🌟 RUNNING IN PORTFOLIO DEMO MODE (Supabase Cloud Bypassed) 🌟');
  } else if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      debugPrint('Supabase successfully initialized with cloud database.');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  } else {
    debugPrint(
      'Supabase credentials not configured in .env yet. Running in offline/local storage mode.',
    );
  }

  runApp(const CoachingApp());
}

class CoachingApp extends StatelessWidget {
  const CoachingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Deepti Joshi Coaching Academy - Mathematics Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
