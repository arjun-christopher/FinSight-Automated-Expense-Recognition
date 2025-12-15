# Authentication Module Documentation

## Overview

The Authentication Module provides Firebase-based Google Sign-In for FinSight, enabling secure user authentication with automatic session persistence and seamless sign-out functionality.

### Key Features

- **Google Sign-In**: One-tap authentication with Google accounts
- **Session Persistence**: Automatic session restoration across app restarts
- **Sign Out**: Clean sign-out from both Firebase and Google
- **User Profile**: Access to user information (name, email, photo)
- **Account Management**: Delete account functionality
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Auth State Management**: Reactive auth state with Riverpod providers

## Architecture

### File Structure

```
lib/
├── services/
│   └── auth_service.dart                 # Core authentication logic
├── features/
│   └── auth/
│       ├── providers/
│       │   └── auth_providers.dart       # Riverpod providers
│       └── presentation/
│           └── pages/
│               ├── login_page.dart       # Login screen
│               └── profile_page.dart     # Profile/logout screen
└── examples/
    └── auth_examples.dart                # Usage examples
```

### Dependencies

```yaml
dependencies:
  firebase_core: ^2.24.2      # Firebase initialization
  firebase_auth: ^4.15.3      # Firebase Authentication
  google_sign_in: ^6.1.6      # Google Sign-In
  flutter_riverpod: ^2.4.9    # State management
```

## Core Components

### 1. AuthService

The main service handling all authentication operations.

#### Initialization

```dart
final authService = AuthService();
```

#### Key Methods

**Sign in with Google**
```dart
User? user = await authService.signInWithGoogle();
if (user != null) {
  print('Signed in as: ${user.email}');
}
```

**Sign out**
```dart
await authService.signOut();
```

**Check if signed in**
```dart
bool isSignedIn = authService.isSignedIn;
```

**Get current user**
```dart
User? user = authService.currentUser;
String? email = authService.email;
String? displayName = authService.displayName;
String? photoURL = authService.photoURL;
String? uid = authService.uid;
```

**Delete account**
```dart
await authService.deleteAccount();
// Note: May require recent authentication
```

**Re-authenticate**
```dart
User? user = await authService.reauthenticateWithGoogle();
```

#### Authentication State Streams

```dart
// Listen to auth state changes (sign in/out)
authService.authStateChanges.listen((User? user) {
  if (user != null) {
    print('User is signed in');
  } else {
    print('User is signed out');
  }
});

// Listen to user changes (includes token refresh)
authService.userChanges.listen((User? user) {
  // User data updated
});
```

### 2. Auth Providers

Riverpod providers for reactive authentication state.

#### Available Providers

**authServiceProvider**
```dart
final authService = ref.read(authServiceProvider);
```

**authStateProvider** - Stream of auth state changes
```dart
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) => user != null ? 'Signed in' : 'Signed out',
  loading: () => 'Loading...',
  error: (error, stack) => 'Error: $error',
);
```

**currentUserProvider** - Current signed-in user
```dart
final user = ref.watch(currentUserProvider);
print(user?.email);
```

**currentUserDataProvider** - UserData object
```dart
final userData = ref.watch(currentUserDataProvider);
if (userData != null) {
  print(userData.greeting);  // "Hello, John"
  print(userData.initials);   // "JD"
}
```

**authStateEnumProvider** - AuthState enum
```dart
final authState = ref.watch(authStateEnumProvider);
switch (authState) {
  case AuthState.authenticated:
    // Show app content
  case AuthState.unauthenticated:
    // Show login screen
  case AuthState.loading:
    // Show loading indicator
  case AuthState.error:
    // Show error message
}
```

**isSignedInProvider** - Boolean check
```dart
final isSignedIn = ref.watch(isSignedInProvider);
if (isSignedIn) {
  // User is authenticated
}
```

**authControllerProvider** - Auth actions controller
```dart
// Sign in
await ref.read(authControllerProvider.notifier).signInWithGoogle();

// Sign out
await ref.read(authControllerProvider.notifier).signOut();

// Delete account
await ref.read(authControllerProvider.notifier).deleteAccount();

// Re-authenticate
await ref.read(authControllerProvider.notifier).reauthenticateWithGoogle();

// Check loading state
final isLoading = ref.watch(authControllerProvider).isLoading;
```

### 3. UserData Class

Helper class for accessing user information.

```dart
final userData = UserData.fromFirebaseUser(firebaseUser);

// Properties
userData.uid              // User ID
userData.email            // Email address
userData.displayName      // Display name
userData.photoURL         // Profile photo URL
userData.isEmailVerified  // Email verification status
userData.createdAt        // Account creation time
userData.lastSignInAt     // Last sign-in time

// Computed properties
userData.initials         // "JD" from "John Doe"
userData.greeting         // "Hello, John"
```

### 4. AuthException

Custom exception for authentication errors.

```dart
try {
  await authService.signInWithGoogle();
} on AuthException catch (e) {
  print('Auth error: ${e.message}');
  print('Error code: ${e.code}');
}
```

#### Common Error Codes

| Code | Description |
|------|-------------|
| `account-exists-with-different-credential` | Account exists with different sign-in method |
| `invalid-credential` | Credential is malformed or expired |
| `operation-not-allowed` | Sign-in method not enabled |
| `user-disabled` | User account has been disabled |
| `user-not-found` | No user found with credential |
| `network-request-failed` | Network error |
| `too-many-requests` | Too many requests, try later |
| `requires-recent-login` | Operation requires recent authentication |

## User Interface

### LoginPage

Complete login screen with Google Sign-In.

**Features:**
- App logo and branding
- Google Sign-In button
- Loading states
- Error handling
- Features list
- Terms and privacy notice

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const LoginPage()),
);
```

### ProfilePage

User profile page with account information and logout.

**Features:**
- User profile display (photo, name, email)
- Account information card
- Sign-out button
- Delete account option
- Confirmation dialogs

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ProfilePage()),
);
```

## Integration Guide

### Step 1: Configure Firebase

Follow the [Firebase Setup Guide](FIREBASE_SETUP.md) to:
1. Create Firebase project
2. Enable Google Sign-In
3. Configure Android app
4. Configure iOS app
5. Download configuration files

### Step 2: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 3: Setup Auth-Based Routing

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'FinSight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          }
          return const HomePage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Authentication Error: $error'),
          ),
        ),
      ),
    );
  }
}
```

### Step 4: Add Profile Page to App Menu

```dart
Drawer(
  child: ListView(
    children: [
      UserAccountsDrawerHeader(
        accountName: Text(userData?.displayName ?? 'User'),
        accountEmail: Text(userData?.email ?? ''),
        currentAccountPicture: CircleAvatar(
          backgroundImage: userData?.photoURL != null
              ? NetworkImage(userData!.photoURL!)
              : null,
          child: userData?.photoURL == null
              ? Text(userData?.initials ?? '?')
              : null,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Profile'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        },
      ),
    ],
  ),
)
```

## Session Persistence

Session persistence is **automatic** with Firebase Auth. The authentication state is automatically restored when the app restarts.

### How It Works

1. User signs in → Firebase stores credentials securely
2. App closes → Credentials remain stored
3. App reopens → `authStateProvider` emits current user automatically
4. No manual persistence needed

### Example

```dart
// No code needed! Just listen to authStateProvider
final authState = ref.watch(authStateProvider);

authState.when(
  data: (user) {
    if (user != null) {
      // User is signed in (even after app restart)
      return HomePage();
    } else {
      // User is not signed in
      return LoginPage();
    }
  },
  loading: () => LoadingScreen(),
  error: (e, _) => ErrorScreen(),
);
```

## Common Use Cases

### 1. Protected Routes

```dart
class ProtectedPage extends ConsumerWidget {
  const ProtectedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    
    if (!isSignedIn) {
      // Redirect to login
      return const LoginPage();
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Content')),
      body: const Center(child: Text('Only signed-in users see this')),
    );
  }
}
```

### 2. Conditional UI

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isSignedIn = ref.watch(isSignedInProvider);
  
  return Scaffold(
    appBar: AppBar(
      actions: [
        if (isSignedIn)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('Sign In'),
          ),
      ],
    ),
  );
}
```

### 3. Listen to Auth State Changes

```dart
class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state and show snackbar on changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && previous?.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, ${user.displayName}!')),
          );
        } else if (user == null && previous?.value != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out')),
          );
        }
      });
    });

    return Scaffold(/* ... */);
  }
}
```

### 4. Display User Greeting

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final userData = ref.watch(currentUserDataProvider);
  
  return Text(
    userData?.greeting ?? 'Welcome!',
    style: const TextStyle(fontSize: 24),
  );
}
```

### 5. Sign Out with Confirmation

```dart
Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
```

## API Reference

### AuthService

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `signInWithGoogle()` | - | `Future<User?>` | Sign in with Google |
| `signOut()` | - | `Future<void>` | Sign out |
| `deleteAccount()` | - | `Future<void>` | Delete user account |
| `reauthenticateWithGoogle()` | - | `Future<User?>` | Re-authenticate |
| `reloadUser()` | - | `Future<void>` | Reload user data |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentUser` | `User?` | Current signed-in user |
| `isSignedIn` | `bool` | Whether user is signed in |
| `displayName` | `String?` | User's display name |
| `email` | `String?` | User's email |
| `photoURL` | `String?` | User's photo URL |
| `uid` | `String?` | User's unique ID |
| `authStateChanges` | `Stream<User?>` | Auth state change stream |
| `userChanges` | `Stream<User?>` | User change stream |

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `authServiceProvider` | `Provider<AuthService>` | AuthService instance |
| `authStateProvider` | `StreamProvider<User?>` | Auth state stream |
| `currentUserProvider` | `Provider<User?>` | Current user |
| `currentUserDataProvider` | `Provider<UserData?>` | Current user data |
| `authStateEnumProvider` | `Provider<AuthState>` | Auth state enum |
| `isSignedInProvider` | `Provider<bool>` | Is signed in check |
| `authControllerProvider` | `StateNotifierProvider` | Auth controller |

## Testing

### Unit Tests

```dart
test('AuthService signs in with Google', () async {
  final authService = AuthService();
  final user = await authService.signInWithGoogle();
  expect(user, isNotNull);
  expect(user?.email, isNotNull);
});

test('AuthService signs out', () async {
  final authService = AuthService();
  await authService.signIn();
  await authService.signOut();
  expect(authService.currentUser, isNull);
});
```

### Widget Tests

```dart
testWidgets('LoginPage displays sign-in button', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: LoginPage()),
    ),
  );
  
  expect(find.text('Sign in with Google'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('Complete sign-in flow', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: MyApp()),
    ),
  );
  
  // Should show login page
  expect(find.byType(LoginPage), findsOneWidget);
  
  // Tap sign-in button
  await tester.tap(find.text('Sign in with Google'));
  await tester.pumpAndSettle();
  
  // Should navigate to home page (after successful sign-in)
  expect(find.byType(HomePage), findsOneWidget);
});
```

## Security Considerations

### Best Practices

1. **Always use HTTPS** for API calls
2. **Validate user on backend** - Never trust client-side auth alone
3. **Use Firebase Security Rules** to protect data
4. **Enable App Check** for production (optional)
5. **Implement proper session timeout** if needed
6. **Log security events** for monitoring

### Firebase Security Rules Example

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Expenses are private to user
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Troubleshooting

See [Firebase Setup Guide](FIREBASE_SETUP.md#troubleshooting) for common issues and solutions.

## Examples

See [auth_examples.dart](lib/examples/auth_examples.dart) for 10 comprehensive examples:

1. Basic Google Sign-In
2. Check Authentication State
3. Display User Profile
4. Protected Route
5. Sign Out
6. Auth State Listener
7. User Data Display
8. Complete Auth Flow
9. Delete Account
10. Error Handling

## Related Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md) - Complete setup instructions
- [Notifications Module](NOTIFICATIONS_MODULE.md) - User-specific notifications
- [Budget Module](BUDGET_MODULE.md) - User-specific budgets
- [Dashboard Module](DASHBOARD.md) - User-specific dashboard

## Future Enhancements

Potential improvements:

1. Email/password authentication
2. Phone authentication
3. Anonymous authentication
4. Multi-factor authentication (MFA)
5. Social sign-in (Facebook, Twitter, Apple)
6. Password reset flow
7. Email verification flow
8. Account linking (multiple providers)
9. Custom claims for role-based access
10. Offline authentication
11. Biometric authentication
12. Session management (multiple devices)

## Conclusion

The Authentication Module provides a complete, production-ready Google Sign-In implementation with automatic session persistence, comprehensive error handling, and a clean, reactive state management system using Riverpod. It's secure, user-friendly, and ready to scale.
