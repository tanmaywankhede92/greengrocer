import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants.dart';
import '../../../../models/user.dart';
import '../../../../providers/dashboard_provider.dart';
import '../../../../services/api_client.dart';
import '../../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;
  final bool serverReachable;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.serverReachable = true,
  });

  AuthState copyWith({bool? isLoading, bool? isAuthenticated, User? user, String? error, bool? serverReachable}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
        serverReachable: serverReachable ?? this.serverReachable,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AuthState(isLoading: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        final cachedUser = await _authService.getCachedUser();
        // Immediately restore authenticated state from secure storage
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: cachedUser,
        );
        _ref.invalidate(dashboardProvider);

        // Background profile sync
        try {
          final user = await _authService.getProfile();
          await _authService.cacheUser(user);
          state = AuthState(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
        } catch (e) {
          // If explicitly 401 Unauthorized, try refresh token
          if (ApiClient.isAuthError(e)) {
            final refreshed = await ApiClient().tryRefreshToken();
            if (refreshed) {
              try {
                final user = await _authService.getProfile();
                await _authService.cacheUser(user);
                state = AuthState(
                  isLoading: false,
                  isAuthenticated: true,
                  user: user,
                );
                _ref.invalidate(dashboardProvider);
                return;
              } catch (_) {}
            }
            // Only if refresh genuinely failed, log out
            await _authService.logout();
            state = const AuthState(isLoading: false, isAuthenticated: false);
          }
          // If network / timeout / server sleeping, KEEP user logged in!
        }
      } else {
        state = const AuthState(isLoading: false, isAuthenticated: false);
      }
    } catch (_) {
      state = const AuthState(isLoading: false, isAuthenticated: false);
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(email: email, password: password);
      state = AuthState(isAuthenticated: true, user: result.user);
      _ref.invalidate(dashboardProvider);
      return null;
    } catch (e) {
      final msg = ApiClient.humanizeError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.register(email: email, password: password, fullName: fullName);
      state = AuthState(isAuthenticated: true, user: result.user);
      _ref.invalidate(dashboardProvider);
      return null;
    } catch (e) {
      final msg = ApiClient.humanizeError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});
