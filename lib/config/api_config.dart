class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
}
