import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../../../../services/auth_service.dart';

/// Profile Page showing user information and account actions
/// 
/// Features:
/// - User profile display
/// - Account information
/// - Sign out button
/// - Delete account option
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    final theme = Theme.of(context);

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with profile picture
            _buildHeader(context, userData, theme),
            
            const SizedBox(height: 24),
            
            // Account Information
            _buildAccountInfo(context, userData, theme),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActions(context, ref, theme),
            
            const SizedBox(height: 24),
            
            // Danger Zone
            _buildDangerZone(context, ref, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserData userData, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture or Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: userData.photoURL != null
                ? NetworkImage(userData.photoURL!)
                : null,
            child: userData.photoURL == null
                ? Text(
                    userData.initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Display Name
          Text(
            userData.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Email
          if (userData.email != null)
            Text(
              userData.email!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(BuildContext context, UserData userData, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow(
                icon: Icons.person,
                label: 'User ID',
                value: userData.uid,
                theme: theme,
              ),
              
              const Divider(height: 24),
              
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: userData.email ?? 'Not available',
                theme: theme,
              ),
              
              const Divider(height: 24),
              
              _buildInfoRow(
                icon: Icons.verified_user,
                label: 'Email Verified',
                value: userData.isEmailVerified ? 'Yes' : 'No',
                theme: theme,
              ),
              
              if (userData.createdAt != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Member Since',
                  value: _formatDate(userData.createdAt!),
                  theme: theme,
                ),
              ],
              
              if (userData.lastSignInAt != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: 'Last Sign In',
                  value: _formatDate(userData.lastSignInAt!),
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, ThemeData theme) {
    final authController = ref.watch(authControllerProvider);
    final isLoading = authController.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              trailing: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: isLoading
                  ? null
                  : () => _handleSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: theme.colorScheme.error.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text(
                'Delete Account',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
              onTap: () => _handleDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
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

    if (confirmed != true) return;

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
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.\n\n'
          'Are you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Re-authenticate before deletion (required for sensitive operations)
      final user = await ref.read(authControllerProvider.notifier).reauthenticateWithGoogle();
      
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Re-authentication cancelled')),
          );
        }
        return;
      }

      // Delete account
      await ref.read(authControllerProvider.notifier).deleteAccount();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
