class ApiConfig {
  // ── Toggle between local and production ──
  // Comment one, uncomment the other:
  // static const String baseUrl = 'http://localhost:5000/api/v1';          // LOCAL
  static const String baseUrl = 'https://greengrocer-903c.onrender.com/api/v1'; // PRODUCTION

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
}
