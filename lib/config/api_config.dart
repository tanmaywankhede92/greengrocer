enum Environment { local, production }

class ApiConfig {
  static Environment current = Environment.production;

  static String get baseUrl {
    switch (current) {
      case Environment.local:
        return 'http://localhost:5000/api/v1';
      case Environment.production:
        return 'https://greengrocer-903c.onrender.com/api/v1';
    }
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
}
