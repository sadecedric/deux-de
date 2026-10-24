import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration de connexion au projet Supabase.
///
/// La clé `anon` est publique par conception : elle ne donne accès qu'à ce
/// que les policies RLS autorisent (voir `supabase/migrations/0001_init.sql`).
/// Ne jamais utiliser la clé `service_role` côté client.
class SupabaseConfig {
  SupabaseConfig._();

  static bool initialized = false;

  static const String url = 'https://dffpbwuruipbvoujjltb.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZnBid3VydWlwYnZvdWpqbHRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0ODgwODQsImV4cCI6MjEwMzA2NDA4NH0.wUjXzAwaeby9GkeRZ9eW22sq76k_Zj_-vx0AqzrdNog';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
    initialized = true;
  }
}

/// Raccourci vers le client Supabase actif.
SupabaseClient get supabase => Supabase.instance.client;
