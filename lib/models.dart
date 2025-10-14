import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RkeUser with ChangeNotifier {
  String uid;
  String name = "";
  String photoURL = "";
  String email = "";

  RkeUser()
      : uid = "",
        name = "",
        photoURL = "https://img.icons8.com/color/96/000000/user.png",
        email = "";

  void changeUser(User? user) {
    if (user != null) {
      uid = user.uid;
      name = user.displayName ?? '';
      photoURL = user.photoURL ?? '';
      email = user.email ?? '';
    } else {
      uid = "";
      name = "";
      photoURL = "https://img.icons8.com/color/96/000000/user.png";
      email = "";
    }
    notifyListeners();
  }
}

class AlbumItem {
  String path;
  String url;
  String hashCd;
  String uid;

  AlbumItem(this.path, this.hashCd, this.uid, this.url);
}

class AlbumData with ChangeNotifier {
  List<AlbumItem> images = <AlbumItem>[];

  void addImage(AlbumItem item) {
    this.images.add(item);
    notifyListeners();
  }
}

class UserData with ChangeNotifier {
  String url = "";

  UserData();

  void changeUserData() {
    this.url = "";
  }
}
