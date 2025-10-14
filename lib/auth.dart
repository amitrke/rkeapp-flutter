import 'models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<User?> user; // firebase user
  final PublishSubject<bool> loading = PublishSubject<bool>();
  Stream<RkeUser>? rkeUserStream;
  late RkeUser rkeUser;

  // constructor
  AuthService() {
    user = _auth.authStateChanges();
    rkeUser = RkeUser();
    user.listen((event) {
      rkeUser.changeUser(event);
    });
  }

  Future<User?> googleSignIn() async {
    try {
      loading.add(true);
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        loading.add(false);
        return null; // user cancelled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        updateUserData(user);
        // ignore: avoid_print
        print("user name: ${user.displayName}");
      }

      loading.add(false);
      return user;
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
    final existing = await userRef.get();
    // ignore: avoid_print
    print(existing);
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
      return 'SignOut';
    } catch (e) {
      return e.toString();
    }
  }
}

// TODO refactor global to InheritedWidget
final AuthService authService = AuthService();
