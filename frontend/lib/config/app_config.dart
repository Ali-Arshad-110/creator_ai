class AppConfig {
  static const String appName = 'CreatorAI';
  static const String appVersion = '1.0.0';

  // Base API URLs
  // For local development on Android emulator, use 10.0.2.2 or your machine's IP.
  // For iOS simulator, use localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://blkoxaptcyxpsrboolwe.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJsa294YXB0Y3l4cHNyYm9vbHdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2OTE2MzUsImV4cCI6MjA5NzI2NzYzNX0.LcPfKR8HKEXNLQ_Lo_iofmQbt1foBLgc3loxrrpw85c',
  );

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
