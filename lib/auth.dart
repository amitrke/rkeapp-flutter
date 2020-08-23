import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User> user; // firebase user
  Stream<Map<String, dynamic>> profile; // custom user data in db
  PublishSubject loading = PublishSubject();

  // constructor
  AuthService() {
    user = _auth.authStateChanges();
    user.listen((event) {
      if (event != null && event.uid != null) {
        profile = mapStream({
          "id": event.uid,
          "name": event.displayName,
          "emailVerified": event.emailVerified
        });
      }
    });
  }

  Stream<Map<String, dynamic>> mapStream(Map source) async* {
    for (var k in source.keys) {
      yield { "key": k, "value": source[k] };
    }
  }

  Future<User> googleSignIn() async {
    try {
      loading.add(true);
      GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      updateUserData(userCredential.user);
      print("user name: ${userCredential.user.displayName}");

      loading.add(false);
      return userCredential.user;
    } catch (error) {
      return error;
    }
  }

  void updateUserData(User user) async {
    var existing = await FirebaseDatabase.instance.reference().child('users').child(user.uid).once();
    print(existing);
    FirebaseDatabase.instance.reference().child('users').child(user.uid)
        .set({
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