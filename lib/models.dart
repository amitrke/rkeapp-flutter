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

  void reset() {
    images = <AlbumItem>[];
    notifyListeners();
  }

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

// ---------- Home screen data models ----------

class Post {
  final String id;
  final String title;
  final String intro;
  final String category;
  final String imageUrl;
  final String userId;
  final String authorName;
  final int updateDate;

  Post({
    required this.id,
    required this.title,
    required this.intro,
    required this.category,
    required this.imageUrl,
    required this.userId,
    required this.authorName,
    required this.updateDate,
  });
}

class NewsItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String url;
  final int createdAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.url,
    required this.createdAt,
  });
}

class AppEvent {
  final String id;
  final String name;
  final String description;
  final String date;

  AppEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
  });

  String get formattedMonth {
    try {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return months[DateTime.parse(date).month - 1];
    } catch (_) {
      return '?';
    }
  }

  String get formattedDay {
    try {
      return DateTime.parse(date).day.toString().padLeft(2, '0');
    } catch (_) {
      return '?';
    }
  }
}

class WeatherDay {
  final double temp;
  final String condition;
  final String icon;

  WeatherDay({required this.temp, required this.condition, required this.icon});
}

class AppData with ChangeNotifier {
  List<Post> posts = [];
  List<NewsItem> news = [];
  List<AppEvent> events = [];
  WeatherDay? todayWeather;
  WeatherDay? tomorrowWeather;
  bool loading = true;

  void setLoaded() {
    loading = false;
    notifyListeners();
  }
}
