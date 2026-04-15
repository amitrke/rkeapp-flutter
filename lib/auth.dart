import 'models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _googleServerClientId =
      '473096260334-752319v0jpfkajs4muj07ri12e6215g9.apps.googleusercontent.com';

  late final Stream<User?> user; // firebase user
  final PublishSubject<bool> loading = PublishSubject<bool>();
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
      loading.add(true);

      if (kIsWeb) {
        final UserCredential userCredential =
            await _auth.signInWithPopup(GoogleAuthProvider());
        final User? webUser = userCredential.user;
        if (webUser != null) {
          updateUserData(webUser);
          // ignore: avoid_print
          print("user name: ${webUser.displayName}");
        }
        loading.add(false);
        return webUser;
      }

      // Initialize Google Sign In
      await _initializeGoogleSignIn();

      // Check if platform supports authenticate
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        // Attempt authentication
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

        if (googleUser == null) {
          loading.add(false);
          return null; // user cancelled
        }

        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final GoogleSignInClientAuthorization? googleAccess = await googleUser
            .authorizationClient
            .authorizationForScopes(<String>['email', 'profile']);

        if (googleAuth.idToken == null) {
          loading.add(false);
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
          // ignore: avoid_print
          print("user name: ${user.displayName}");
        }

        loading.add(false);
        return user;
      } else {
        // This platform requires an alternative sign-in UI integration.
        loading.add(false);
        return null;
      }
    } on GoogleSignInException catch (error) {
      // ignore: avoid_print
      print('GoogleSignInException(${error.code}): ${error.description}');
      loading.add(false);
      return null;
    } catch (error) {
      // ignore: avoid_print
      print(error);
      loading.add(false);
      return null;
    }
  }

  void updateUserData(User user) async {
    final db = FirebaseDatabase.instance.ref();
    final userRef = db.child('users').child(user.uid);
    await userRef.get();
    await userRef.set({
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'lastSeen': DateTime.now().toIso8601String()
    });
  }

  Future<String> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
      return 'SignOut';
    } catch (e) {
      return e.toString();
    }
  }
}

// TODO refactor global to InheritedWidget
final AuthService authService = AuthService();
