import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl {
    return dotenv.get('SUPABASE_URL', fallback: 'URL_DE_SUPABASE');
  }

  static String get supabaseAnonKey {
    return dotenv.get('SUPABASE_ANON_KEY', fallback: 'ANON_KEY');
  }
}
