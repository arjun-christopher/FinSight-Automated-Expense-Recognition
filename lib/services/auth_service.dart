import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication Service for FinSight
/// 
/// Handles all authentication operations including:
/// - Google Sign-In
/// - Sign out
/// - Session management
/// - User state monitoring
/// 
/// Usage:
/// ```dart
/// final authService = AuthService();
/// final user = await authService.signInWithGoogle();
/// ```
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user changes stream (includes token refresh)
  Stream<User?> get userChanges => _auth.userChanges();

  /// Sign in with Google
  /// 
  /// Returns the signed-in User or null if sign-in was cancelled
  /// Throws FirebaseAuthException if sign-in fails
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      throw _handleAuthException(e);
    } catch (e) {
      // Handle other errors
      throw AuthException('An unexpected error occurred during sign-in: $e');
    }
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get current user's display name
  String? get displayName => currentUser?.displayName;

  /// Get current user's email
  String? get email => currentUser?.email;

  /// Get current user's photo URL
  String? get photoURL => currentUser?.photoURL;

  /// Get current user's UID
  String? get uid => currentUser?.uid;

  /// Reload current user data
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Delete current user account
  /// 
  /// Note: This requires recent authentication.
  /// If the user signed in too long ago, this will throw an error.
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'This operation requires recent authentication. Please sign in again.',
        );
      }
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate with Google
  /// 
  /// Useful before sensitive operations like account deletion
  Future<User?> reauthenticateWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await currentUser?.reauthenticateWithCredential(credential);
      return userCredential?.user;
    } catch (e) {
      throw AuthException('Re-authentication failed: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  AuthException _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'account-exists-with-different-credential':
        message = 'An account already exists with a different sign-in method.';
        break;
      case 'invalid-credential':
        message = 'The credential is malformed or has expired.';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'user-not-found':
        message = 'No user found with this credential.';
        break;
      case 'wrong-password':
        message = 'Invalid password.';
        break;
      case 'invalid-verification-code':
        message = 'Invalid verification code.';
        break;
      case 'invalid-verification-id':
        message = 'Invalid verification ID.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Please try again later.';
        break;
      case 'requires-recent-login':
        message = 'This operation requires recent authentication.';
        break;
      default:
        message = 'Authentication error: ${e.message ?? e.code}';
    }
    
    return AuthException(message, code: e.code);
  }
}

/// Custom Authentication Exception
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// User authentication state
enum AuthState {
  /// User is not authenticated
  unauthenticated,
  
  /// User is authenticated
  authenticated,
  
  /// Authentication state is being checked
  loading,
  
  /// Authentication error occurred
  error,
}

/// User data class for easier access to user information
class UserData {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  const UserData({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastSignInAt,
  });

  /// Create UserData from Firebase User
  factory UserData.fromFirebaseUser(User user) {
    return UserData(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  /// Get initials from display name
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email?.substring(0, 1).toUpperCase() ?? '?';
    }
    
    final parts = displayName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  /// Get greeting message
  String get greeting {
    final name = displayName ?? email?.split('@')[0] ?? 'User';
    return 'Hello, $name';
  }

  /// Copy with method
  UserData copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserData &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'UserData(uid: $uid, email: $email, displayName: $displayName)';
  }
}
