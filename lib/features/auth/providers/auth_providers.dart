import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for Firebase auth state changes
/// 
/// Emits User? whenever the authentication state changes:
/// - User signs in -> emits User
/// - User signs out -> emits null
/// - App starts -> emits current user or null
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user
/// 
/// Returns the currently signed-in User or null if not signed in
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Provider for current user data
/// 
/// Returns UserData object with user information or null if not signed in
final currentUserDataProvider = Provider<UserData?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return UserData.fromFirebaseUser(user);
});

/// Provider for authentication state enum
/// 
/// Returns AuthState indicating current authentication status
final authStateEnumProvider = Provider<AuthState>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) => user != null ? AuthState.authenticated : AuthState.unauthenticated,
    loading: () => AuthState.loading,
    error: (_, __) => AuthState.error,
  );
});

/// Provider for checking if user is signed in
/// 
/// Returns true if user is authenticated, false otherwise
final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Auth controller for handling authentication actions
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthController(this._authService, this._ref) : super(const AsyncValue.data(null));

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Re-authenticate with Google
  Future<User?> reauthenticateWithGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.reauthenticateWithGoogle();
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider for auth controller
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService, ref);
});
