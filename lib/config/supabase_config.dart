import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Get Supabase URL from .env file
  static String get url {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Get Supabase Anon Key from .env file
  static String get anonKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  /// Check whether the user has configured valid Supabase credentials
  static bool get isConfigured {
    final u = url.trim();
    final k = anonKey.trim();
    return u.isNotEmpty &&
        k.isNotEmpty &&
        !u.contains('your-project-id') &&
        !k.contains('your-anon-public-api-key');
  }
}
