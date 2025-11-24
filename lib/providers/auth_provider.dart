// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart'; 
import '../services/auth_service.dart';
import '../services/api_service.dart';


// State class untuk Auth
class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized; 

  AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    initializeUser();
  }

  // Memuat data pengguna dari SharedPreferences saat aplikasi dibuka
  Future<void> initializeUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.loadUserFromStorage(); // Menggunakan loadUserFromStorage
      state = state.copyWith(
        currentUser: user,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialized: true, errorMessage: 'Gagal memuat sesi.');
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.login(username, password);
      state = state.copyWith(
        currentUser: user,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        currentUser: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan login.',
        currentUser: null,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.logout();
      state = state.copyWith(
        currentUser: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        currentUser: null, 
      );
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});