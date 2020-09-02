import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RkeUser with ChangeNotifier {
  String uid;
  String name = "";
  String photoURL = "";
  String email = "";

  RkeUser() {
    this.uid = "";
    this.name = "";
    this.photoURL = "https://img.icons8.com/color/96/000000/user.png";
    this.email = "";
  }

  void changeUser(User user) {
    if (user != null) {
      this.uid = user.uid ?? '';
      this.name = user.displayName ?? '';
      this.photoURL = user.photoURL ?? '';
      this.email = user.email ?? '';
    } else {
      this.uid = "";
      this.name = "";
      this.photoURL = "https://img.icons8.com/color/96/000000/user.png";
      this.email = "";
    }
    notifyListeners();
  }
}

class AlbumItem {
  String path;
  String hashCd;
  String uid;
}

class AlbumData with ChangeNotifier {
  List<AlbumItem> images;

  AlbumData() {
    images = new List();
  }

  void addImage() {}
}

class UserData with ChangeNotifier {
  String url;

  UserData() {
    this.url = "";
  }

  void changeUserData() {
    this.url = "";
  }
}
