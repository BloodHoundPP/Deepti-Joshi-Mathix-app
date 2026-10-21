import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Default cloud project credentials as fallback (e.g. CI/CD or release APK builds)
  static const String _defaultUrl = 'https://srbwtfkffpwrvdbvsbya.supabase.co';
  static const String _defaultAnonKey = 'sb_publishable_iMXhjYcJPKIvVHSK3_G5fA__4-IN327';

  /// Get Supabase URL from .env file or fallback
  static String get url {
    if (dotenv.isInitialized) {
      final val = dotenv.env['SUPABASE_URL']?.trim() ?? '';
      if (val.isNotEmpty && !val.contains('your-project-id')) {
        return val;
      }
    }
    return _defaultUrl;
  }

  /// Get Supabase Anon Key from .env file or fallback
  static String get anonKey {
    if (dotenv.isInitialized) {
      final val = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
      if (val.isNotEmpty && !val.contains('your-anon-public-api-key')) {
        return val;
      }
    }
    return _defaultAnonKey;
  }

  /// Check whether valid Supabase credentials are ready
  static bool get isConfigured {
    final u = url.trim();
    final k = anonKey.trim();
    return u.isNotEmpty &&
        k.isNotEmpty &&
        !u.contains('your-project-id') &&
        !k.contains('your-anon-public-api-key');
  }
}

