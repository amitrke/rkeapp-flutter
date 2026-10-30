import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth.dart';
import 'contact.dart';
import 'models.dart';
import 'theme.dart';

/// Account settings: contact, sign out, and account deletion.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deletingAccount = false;

  Future<void> _signOut() async {
    await authService.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteAccount(RkeUser user) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
        title: const Text('Delete your account?'),
        content: Text(
          user.email.isNotEmpty
              ? 'This permanently deletes ${user.email}, including your profile, posts, albums, notifications, and uploaded photos. This cannot be undone.'
              : 'This permanently deletes your profile, posts, albums, notifications, and uploaded photos. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final result = await authService.deleteCurrentUserAccount();
    if (!mounted) return;

    setState(() => _deletingAccount = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.deleted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context);
    final scheme = Theme.of(context).colorScheme;
    final signedIn = user.uid.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Space.s),
        children: [
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact us'),
            subtitle: const Text('Questions, feedback or a problem to report'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            ),
          ),
          if (signedIn) ...[
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: user.email.isNotEmpty ? Text(user.email) : null,
              onTap: _deletingAccount ? null : _signOut,
            ),
            const Divider(height: Space.xl),
            ListTile(
              leading: _deletingAccount
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                _deletingAccount ? 'Deleting account…' : 'Delete account',
                style: TextStyle(color: scheme.error),
              ),
              subtitle: const Text(
                'Removes your account, posts, albums and photos.',
              ),
              onTap: _deletingAccount ? null : () => _confirmDeleteAccount(user),
            ),
          ],
        ],
      ),
    );
  }
}
