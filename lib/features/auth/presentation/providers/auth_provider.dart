import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants.dart';
import '../../../../models/user.dart';
import '../../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isLoading, bool? isAuthenticated, User? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        final user = await _authService.getProfile();
        state = AuthState(isAuthenticated: true, user: user);
      }
    } catch (_) {
      await _authService.logout();
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(email: email, password: password);
      state = AuthState(isAuthenticated: true, user: result.user);
      return null;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.register(email: email, password: password, fullName: fullName);
      state = AuthState(isAuthenticated: true, user: result.user);
      return null;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);

  String _extractError(Object e) {
    if (e is Exception) {
      final s = e.toString();
      if (s.contains('message')) {
        try {
          final json = s.split('message: ').last.replaceAll('}', '').trim();
          return json;
        } catch (_) {}
      }
    }
    return 'Something went wrong';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
