import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth.dart';

/// Starts sign-in. On iOS offers Google and Apple; elsewhere goes straight to Google.
Future<void> startSignIn(BuildContext context) async {
  if (!kIsWeb && Platform.isIOS) {
    await _showSignInSheet(context);
    return;
  }
  final user = await authService.googleSignIn();
  if (user == null && context.mounted) {
    _showFailure(context, 'Google sign-in didn\'t complete. Try again.');
  }
}

void _showFailure(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _showSignInSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Sign in with Google'),
            onTap: () async {
              Navigator.of(ctx).pop();
              final signedInUser = await authService.googleSignIn();
              if (!context.mounted || signedInUser != null) return;
              _showFailure(context, 'Google sign-in didn\'t complete. Try again.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.apple),
            title: const Text('Sign in with Apple'),
            onTap: () async {
              Navigator.of(ctx).pop();
              final signedInUser = await authService.appleSignIn();
              if (!context.mounted || signedInUser != null) return;
              _showFailure(
                context,
                'Apple sign-in didn\'t complete. Verify Sign in with Apple in Apple/Firebase config and try again.',
              );
            },
          ),
        ],
      ),
    ),
  );
}
