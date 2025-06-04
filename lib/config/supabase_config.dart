class SupabaseConfig {
  // Supabase project configuration
  // Project URL extracted from the provided API key
  static const String url = 'https://pvfqsdsjeibeuodmndtd.supabase.co';

  // Anon public key provided by the user
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZnFzZHNqZWliZXVvZG1uZHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NDgwODAsImV4cCI6MjA2NDQyNDA4MH0.jFXO_k5sN2YQPPSosdERu71yM9pbT0raby14EpIusa4';

  // Check if Supabase is configured
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  // Re-enable Supabase to test auto update functionality
  // If connection fails, UpdateService will handle gracefully and log errors
  static const bool enableSupabase = true;
}
