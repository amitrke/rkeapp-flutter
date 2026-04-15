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

class AppAlbum {
  final String id;
  final String name;
  final String description;
  final String userId;
  final List<String> images;
  final int updateDate;
  final String coverUrl;

  AppAlbum({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.images,
    required this.updateDate,
    required this.coverUrl,
  });
}

class WeatherDay {
  final double temp;
  final String condition;
  final String icon;

  WeatherDay({required this.temp, required this.condition, required this.icon});
}

class WeatherSummary {
  final String main;
  final String description;
  final String icon;

  WeatherSummary({
    required this.main,
    required this.description,
    required this.icon,
  });
}

class WeatherCurrent {
  final int dt;
  final double temp;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final double uvi;
  final int clouds;
  final int visibility;
  final WeatherSummary summary;

  WeatherCurrent({
    required this.dt,
    required this.temp,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.uvi,
    required this.clouds,
    required this.visibility,
    required this.summary,
  });
}

class WeatherHourly {
  final int dt;
  final double temp;
  final WeatherSummary summary;

  WeatherHourly({
    required this.dt,
    required this.temp,
    required this.summary,
  });
}

class WeatherDaily {
  final int dt;
  final double dayTemp;
  final double minTemp;
  final double maxTemp;
  final WeatherSummary summary;

  WeatherDaily({
    required this.dt,
    required this.dayTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.summary,
  });
}

class WeatherDetails {
  final String timezone;
  final int timezoneOffset;
  final WeatherCurrent current;
  final List<WeatherHourly> hourly;
  final List<WeatherDaily> daily;

  WeatherDetails({
    required this.timezone,
    required this.timezoneOffset,
    required this.current,
    required this.hourly,
    required this.daily,
  });
}

class AppData with ChangeNotifier {
  List<Post> posts = [];
  List<NewsItem> news = [];
  List<AppEvent> events = [];
  List<AppAlbum> albums = [];
  WeatherDay? todayWeather;
  WeatherDay? tomorrowWeather;
  WeatherDetails? weatherDetails;
  bool loading = true;

  void setLoaded() {
    loading = false;
    notifyListeners();
  }
}
