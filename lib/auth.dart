import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'collections.dart';
import 'models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AccountDeletionResult {
  final bool deleted;
  final String message;

  const AccountDeletionResult({
    required this.deleted,
    required this.message,
  });
}

class _AppleRevocationContext {
  final String authorizationCode;
  final String identityToken;

  const _AppleRevocationContext({
    required this.authorizationCode,
    required this.identityToken,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _googleServerClientId =
      '473096260334-752319v0jpfkajs4muj07ri12e6215g9.apps.googleusercontent.com';
  static const String _appleRevocationEndpoint = String.fromEnvironment(
    'APPLE_ACCOUNT_REVOCATION_URL',
  );

  late final Stream<User?> user; // firebase user
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();
  Stream<bool> get loading => _loadingController.stream;
  Stream<RkeUser>? rkeUserStream;
  late RkeUser rkeUser;
  bool _initialized = false;

  // constructor
  AuthService() {
    user = _auth.authStateChanges();
    rkeUser = RkeUser();
    user.listen((event) {
      rkeUser.changeUser(event);
    });
  }

  Future<void> _initializeGoogleSignIn() async {
    if (!_initialized && !kIsWeb) {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      _initialized = true;
    }
  }

  Future<User?> googleSignIn() async {
    try {
      _loadingController.add(true);

      if (kIsWeb) {
        final UserCredential userCredential =
            await _auth.signInWithPopup(GoogleAuthProvider());
        final User? webUser = userCredential.user;
        if (webUser != null) {
          updateUserData(webUser);
        }
        _loadingController.add(false);
        return webUser;
      }

      // Initialize Google Sign In
      await _initializeGoogleSignIn();

      // Check if platform supports authenticate
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        // Attempt authentication
        final googleUser = await GoogleSignIn.instance.authenticate();

        // Get authentication details
        final googleAuth = googleUser.authentication;
        final GoogleSignInClientAuthorization? googleAccess = await googleUser
            .authorizationClient
            .authorizationForScopes(<String>['email', 'profile']);

        if (googleAuth.idToken == null) {
          _loadingController.add(false);
          return null;
        }

        // Create a new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAccess?.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user != null) {
          updateUserData(user);
        }

        _loadingController.add(false);
        return user;
      } else {
        // This platform requires an alternative sign-in UI integration.
        _loadingController.add(false);
        return null;
      }
    } on GoogleSignInException catch (_) {
      _loadingController.add(false);
      return null;
    } catch (_) {
      _loadingController.add(false);
      return null;
    }
  }

  // ── Apple Sign-In helpers ─────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<User?> appleSignIn() async {
    try {
      _loadingController.add(true);

      if (!await SignInWithApple.isAvailable()) {
        _loadingController.add(false);
        return null;
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        _loadingController.add(false);
        return null;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user != null) {
        // Apple only provides name on the very first sign-in.
        // Persist it to the Firebase Auth profile so it survives re-logins.
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        if (givenName != null || familyName != null) {
          final fullName = [givenName, familyName]
              .where((n) => n != null && n.isNotEmpty)
              .join(' ');
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(fullName);
            await user.reload();
          }
        }
        updateUserData(_auth.currentUser ?? user);
      }
      _loadingController.add(false);
      return user;
    } on SignInWithAppleAuthorizationException catch (_) {
      _loadingController.add(false);
      return null;
    } on FirebaseAuthException catch (_) {
      _loadingController.add(false);
      return null;
    } catch (_) {
      _loadingController.add(false);
      return null;
    }
  }

  Future<AccountDeletionResult> deleteCurrentUserAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const AccountDeletionResult(
        deleted: false,
        message: 'No signed-in account was found.',
      );
    }

    try {
      _loadingController.add(true);
      await currentUser.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        return const AccountDeletionResult(
          deleted: false,
          message: 'Your session expired. Please sign in again and retry.',
        );
      }

      final providers =
          refreshedUser.providerData.map((p) => p.providerId).toSet();
      final appleContext = await _reauthenticateForDeletion(refreshedUser);
      final warnings = <String>[];

      if (appleContext != null) {
        final revoked = await _revokeAppleAuthorization(
          user: refreshedUser,
          context: appleContext,
        );
        if (!revoked) {
          warnings.add(
            'Apple token revocation is not configured yet. Set APPLE_ACCOUNT_REVOCATION_URL before App Store submission.',
          );
        }
      }

      await _deleteUserOwnedData(refreshedUser.uid);
      await refreshedUser.delete();
      await _auth.signOut();
      if (!kIsWeb && providers.contains('google.com')) {
        await GoogleSignIn.instance.signOut();
      }

      final message = warnings.isEmpty
          ? 'Your account and associated data were deleted.'
          : 'Your account and associated data were deleted. ${warnings.join(' ')}';
      return AccountDeletionResult(deleted: true, message: message);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        return const AccountDeletionResult(
          deleted: false,
          message: 'Please reauthenticate and try deleting your account again.',
        );
      }
      if (error.code == 'user-cancelled') {
        return const AccountDeletionResult(
          deleted: false,
          message: 'Account deletion was cancelled.',
        );
      }
      return AccountDeletionResult(
        deleted: false,
        message: error.message ?? 'Could not delete your account right now.',
      );
    } catch (error) {
      return AccountDeletionResult(
        deleted: false,
        message: 'Could not delete your account right now: $error',
      );
    } finally {
      _loadingController.add(false);
    }
  }

  Future<_AppleRevocationContext?> _reauthenticateForDeletion(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains('apple.com')) {
      return _reauthenticateWithApple(user);
    }
    if (providers.contains('google.com')) {
      await _reauthenticateWithGoogle(user);
    }
    return null;
  }

  Future<void> _reauthenticateWithGoogle(User user) async {
    if (kIsWeb) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Account deletion reauthentication is not available on web.',
      );
    }

    await _initializeGoogleSignIn();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Google reauthentication is not available on this device.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final googleAccess = await googleUser.authorizationClient
        .authorizationForScopes(<String>['email', 'profile']);

    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Google reauthentication did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAccess?.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<_AppleRevocationContext> _reauthenticateWithApple(User user) async {
    if (!await SignInWithApple.isAvailable()) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Sign in with Apple is not available on this device.',
      );
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: nonce,
    );

    if (appleCredential.identityToken == null ||
        appleCredential.identityToken!.isEmpty) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Apple reauthentication did not return an identity token.',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );
    await user.reauthenticateWithCredential(oauthCredential);

    return _AppleRevocationContext(
      authorizationCode: appleCredential.authorizationCode,
      identityToken: appleCredential.identityToken!,
    );
  }

  Future<bool> _revokeAppleAuthorization({
    required User user,
    required _AppleRevocationContext context,
  }) async {
    if (_appleRevocationEndpoint.isEmpty) {
      return false;
    }

    final response = await http.post(
      Uri.parse(_appleRevocationEndpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': user.uid,
        'email': user.email,
        'authorizationCode': context.authorizationCode,
        'identityToken': context.identityToken,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Apple token revocation failed with status ${response.statusCode}.',
      );
    }

    return true;
  }

  Future<void> _deleteUserOwnedData(String userId) async {
    await _deleteDocsByUserId(Collections.notifications, userId);
    await _deleteDocsByUserId(Collections.moderationQueue, userId);
    await _deleteDocsByUserId(Collections.posts, userId);
    await _deleteDocsByUserId(Collections.albums, userId);
    await FirebaseFirestore.instance.collection(Collections.users).doc(userId).delete();
    await _deleteStorageFolder(FirebaseStorage.instance.ref('users/$userId'));
  }

  Future<void> _deleteDocsByUserId(String collection, String userId) async {
    while (true) {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 100) {
        return;
      }
    }
  }

  Future<void> _deleteStorageFolder(Reference reference) async {
    final items = await reference.listAll();
    for (final prefix in items.prefixes) {
      await _deleteStorageFolder(prefix);
    }
    for (final item in items.items) {
      await item.delete();
    }
  }

  void updateUserData(User user) async {
    // Write user profile to the Firestore `users` collection so it is
    // readable by the web app (rke-nextjs queries users/{uid} by `id` field).
    final data = <String, dynamic>{
      'id': user.uid,
      'lastSeen': DateTime.now().toIso8601String(),
    };
    if (user.email != null) data['email'] = user.email;
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      data['name'] = user.displayName;
    }
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      data['profilePic'] = user.photoURL;
    }
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  Future<String> signOut() async {
    try {
      final providers =
          _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
          [];
      await _auth.signOut();
      if (!kIsWeb && providers.contains('google.com')) {
        await GoogleSignIn.instance.signOut();
      }
      return 'SignOut';
    } catch (e) {
      return e.toString();
    }
  }
}

// TODO refactor global to InheritedWidget
final AuthService authService = AuthService();
