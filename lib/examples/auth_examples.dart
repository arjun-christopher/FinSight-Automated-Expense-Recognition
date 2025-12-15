import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';

/// ============================================================================
/// AUTHENTICATION EXAMPLES FOR FINSIGHT
/// ============================================================================
/// 
/// This file contains 10 comprehensive examples demonstrating how to use
/// the authentication system in FinSight.
/// 
/// Examples included:
/// 1. Basic Google Sign-In
/// 2. Check Authentication State
/// 3. Display User Profile
/// 4. Protected Route
/// 5. Sign Out
/// 6. Auth State Listener
/// 7. User Data Display
/// 8. Complete Auth Flow
/// 9. Delete Account
/// 10. Error Handling
/// 
/// To use these examples:
/// 1. Ensure Firebase is configured (see AUTH_MODULE.md)
/// 2. Copy the relevant example code
/// 3. Integrate into your app
/// ============================================================================

// ============================================================================
// EXAMPLE 1: Basic Google Sign-In
// ============================================================================
// Shows how to implement a simple sign-in button

class Example1BasicSignIn extends ConsumerWidget {
  const Example1BasicSignIn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Basic Sign-In')),
      body: Center(
        child: authController.isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: () => _signIn(context, ref),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      if (user != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${user.displayName}!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ============================================================================
// EXAMPLE 2: Check Authentication State
// ============================================================================
// Demonstrates checking if user is signed in

class Example2CheckAuthState extends ConsumerWidget {
  const Example2CheckAuthState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final authState = ref.watch(authStateEnumProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auth State')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSignedIn ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: isSignedIn ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Auth State: ${authState.name}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'User: ${user?.email ?? "Not signed in"}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Display User Profile
// ============================================================================
// Shows how to display user information

class Example3UserProfile extends ConsumerWidget {
  const Example3UserProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: userData.photoURL != null
                ? NetworkImage(userData.photoURL!)
                : null,
            child: userData.photoURL == null
                ? Text(userData.initials, style: const TextStyle(fontSize: 32))
                : null,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              userData.displayName ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              userData.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('User ID'),
            subtitle: Text(userData.uid),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Email Verified'),
            subtitle: Text(userData.isEmailVerified ? 'Yes' : 'No'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Protected Route
// ============================================================================
// Shows how to create a route that requires authentication

class Example4ProtectedRoute extends ConsumerWidget {
  const Example4ProtectedRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

    if (!isSignedIn) {
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Protected Content')),
      body: const Center(
        child: Text('This content is only visible to signed-in users'),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Sign Out
// ============================================================================
// Demonstrates sign-out functionality

class Example5SignOut extends ConsumerWidget {
  const Example5SignOut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Out')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userData != null) ...[
              Text('Signed in as: ${userData.email}'),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: authController.isLoading
                  ? null
                  : () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ============================================================================
// EXAMPLE 6: Auth State Listener
// ============================================================================
// Shows how to listen to authentication state changes

class Example6AuthStateListener extends ConsumerWidget {
  const Example6AuthStateListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signed in as ${user.email}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signed out')),
            );
          }
        },
        loading: () {},
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth error: $error')),
          );
        },
      );
    });

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Auth State Listener')),
      body: Center(
        child: authState.when(
          data: (user) => Text(
            user != null
                ? 'Signed in as: ${user.email}'
                : 'Not signed in',
            style: const TextStyle(fontSize: 18),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 7: User Data Display
// ============================================================================
// Shows how to use UserData helper class

class Example7UserDataDisplay extends ConsumerWidget {
  const Example7UserDataDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Data')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Greeting'),
              subtitle: Text(userData.greeting),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Initials'),
              subtitle: Text(userData.initials),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Display Name'),
              subtitle: Text(userData.displayName ?? 'N/A'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Email'),
              subtitle: Text(userData.email ?? 'N/A'),
            ),
          ),
          if (userData.createdAt != null)
            Card(
              child: ListTile(
                title: const Text('Member Since'),
                subtitle: Text(userData.createdAt.toString()),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 8: Complete Auth Flow
// ============================================================================
// Demonstrates complete authentication flow with routing

class Example8CompleteAuthFlow extends ConsumerWidget {
  const Example8CompleteAuthFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return const _HomePage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to FinSight!'),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 9: Delete Account
// ============================================================================
// Shows how to delete user account

class Example9DeleteAccount extends ConsumerWidget {
  const Example9DeleteAccount({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: authController.isLoading
                  ? null
                  : () => _deleteAccount(context, ref),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Re-authenticate first
      final user = await ref.read(authControllerProvider.notifier).reauthenticateWithGoogle();
      if (user == null) return;

      // Delete account
      await ref.read(authControllerProvider.notifier).deleteAccount();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ============================================================================
// EXAMPLE 10: Error Handling
// ============================================================================
// Demonstrates comprehensive error handling

class Example10ErrorHandling extends ConsumerStatefulWidget {
  const Example10ErrorHandling({super.key});

  @override
  ConsumerState<Example10ErrorHandling> createState() =>
      _Example10ErrorHandlingState();
}

class _Example10ErrorHandlingState extends ConsumerState<Example10ErrorHandling> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testSignIn,
              child: const Text('Test Sign-In'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSignIn() async {
    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Auth Error: ${e.message} (${e.code})');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected Error: $e');
    }
  }
}

/// ============================================================================
/// USAGE GUIDE
/// ============================================================================
/// 
/// To use these examples in your app:
/// 
/// 1. Import this file:
///    ```dart
///    import 'package:finsight/examples/auth_examples.dart';
///    ```
/// 
/// 2. Navigate to an example:
///    ```dart
///    Navigator.push(
///      context,
///      MaterialPageRoute(builder: (context) => Example1BasicSignIn()),
///    );
///    ```
/// 
/// 3. Or copy the code and integrate into your screens
/// 
/// Key Points:
/// - Always wrap auth operations in try-catch blocks
/// - Use authStateProvider to listen to auth changes
/// - Check isSignedInProvider for simple boolean checks
/// - Handle loading states with authController.isLoading
/// - Use UserData class for convenient user info access
/// 
/// ============================================================================
