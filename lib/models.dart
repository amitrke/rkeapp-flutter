import 'package:firebase_auth/firebase_auth.dart';

class RkeUser {
  final String name;
  final String photoURL;
  final String email;

  RkeUser({this.name, this.email, this.photoURL});

  factory RkeUser.fromUser(User user){
    if (user != null) {
      return RkeUser(
          name: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          email: user.email ?? ''
      );
    }
    else {
      return RkeUser(email: "", name: "", photoURL: "https://img.icons8.com/color/96/000000/user.png");
    }
  }
}