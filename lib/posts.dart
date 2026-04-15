import 'models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Converts a raw filename stored in Firestore (e.g. "photo.jpg") into the
/// medium-size Firebase Storage path used by the web app.
String _storagePath(String userId, String filename) {
  final lastDot = filename.lastIndexOf('.');
  final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
  final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
  return 'users/$userId/images/${base}_680x680.$ext';
}

/// Returns a download URL for the image. Accepts either an existing https URL
/// or a raw filename that needs to be resolved via Firebase Storage.
Future<String> _resolveImage(String userId, String filename) async {
  if (filename.startsWith('http')) return filename;
  try {
    return await FirebaseStorage.instance
        .ref(_storagePath(userId, filename))
        .getDownloadURL();
  } catch (_) {
    return '';
  }
}

class AppDataService {
  final AppData appData = AppData();

  AppDataService() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPosts(),
      _loadNews(),
      _loadEvents(),
      _loadAlbums(),
      _loadWeather(),
    ]);
    appData.setLoaded();
  }

  Future<void> _loadPosts() async {
    try {
      // ignore: avoid_print
      print('[AppData] _loadPosts: querying...');
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('public', isEqualTo: true)
          .where('approved', isEqualTo: true)
          .orderBy('updateDate', descending: true)
          .limit(4)
          .get();
      // ignore: avoid_print
      print('[AppData] _loadPosts: got ${snap.docs.length} docs');

      final List<Post> posts = [];
      for (final doc in snap.docs) {
        final d = doc.data();
        final userId = d['userId'] as String? ?? '';
        final rawImages = List<String>.from(d['images'] as List? ?? []);

        String imageUrl = '';
        if (rawImages.isNotEmpty) {
          imageUrl = await _resolveImage(userId, rawImages[0]);
        }

        String authorName = 'Community Member';
        try {
          final uSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('id', isEqualTo: userId)
              .limit(1)
              .get();
          if (uSnap.docs.isNotEmpty) {
            authorName =
                uSnap.docs.first.data()['name'] as String? ?? authorName;
          }
        } catch (_) {}

        posts.add(Post(
          id: doc.id,
          title: d['title'] as String? ?? '',
          intro: d['intro'] as String? ?? '',
          category: d['category'] as String? ?? '',
          imageUrl: imageUrl,
          userId: userId,
          authorName: authorName,
          updateDate: d['updateDate'] as int? ?? 0,
        ));
      }
      appData.posts = posts;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AppData] _loadPosts ERROR: $e\n$st');
    }
  }

  Future<void> _loadNews() async {
    try {
      // ignore: avoid_print
      print('[AppData] _loadNews: querying...');
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('expireAt', descending: true)
          .limit(4)
          .get();
      // ignore: avoid_print
      print('[AppData] _loadNews: got ${snap.docs.length} docs');

      appData.news = snap.docs.map((doc) {
        final d = doc.data();
        return NewsItem(
          id: doc.id,
          title: d['title'] as String? ?? '',
          description: d['description'] as String? ?? '',
          imageUrl: (d['image_url'] as String?) ?? (d['imageUrl'] as String?) ?? '',
          url: d['url'] as String? ?? d['link'] as String? ?? '',
          createdAt: (d['createdAt'] as int?) ??
              DateTime.tryParse(d['publishedAt'] as String? ?? '')
                      ?.millisecondsSinceEpoch ??
              0,
        );
      }).toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('[AppData] _loadNews ERROR: $e\n$st');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      // ignore: avoid_print
      print('[AppData] _loadEvents: querying (today=$today)...');
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: today)
          .orderBy('date')
          .limit(4)
          .get();
      // ignore: avoid_print
      print('[AppData] _loadEvents: got ${snap.docs.length} docs');

      appData.events = snap.docs.map((doc) {
        final d = doc.data();
        return AppEvent(
          id: doc.id,
          name: d['name'] as String? ?? '',
          description: d['description'] as String? ?? '',
          date: d['date'] as String? ?? '',
        );
      }).toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('[AppData] _loadEvents ERROR: $e\n$st');
    }
  }

  Future<void> _loadWeather() async {
    try {
      // ignore: avoid_print
      print('[AppData] _loadWeather: querying...');
      final doc = await FirebaseFirestore.instance
          .doc('weather/roorkee-in')
          .get();
      // ignore: avoid_print
      print('[AppData] _loadWeather: exists=${doc.exists}');
      if (!doc.exists) return;
      final data = doc.data()!;

      final current = data['current'] as Map<String, dynamic>?;
      if (current != null) {
        final cw =
            (current['weather'] as List?)?.first as Map<String, dynamic>?;
        appData.todayWeather = WeatherDay(
          temp: (current['temp'] as num?)?.toDouble() ?? 0.0,
          condition: cw?['main'] as String? ?? '',
          icon: cw?['icon'] as String? ?? '',
        );
      }

      final dailyForecasts = data['daily'] as List<dynamic>?;
      if (dailyForecasts != null && dailyForecasts.length > 1) {
        final tomorrow = dailyForecasts[1] as Map<String, dynamic>;
        final tTemp =
            (tomorrow['temp'] as Map<String, dynamic>?)?['day'] as num?;
        final tw =
            (tomorrow['weather'] as List?)?.first as Map<String, dynamic>?;
        appData.tomorrowWeather = WeatherDay(
          temp: tTemp?.toDouble() ?? 0.0,
          condition: tw?['main'] as String? ?? '',
          icon: tw?['icon'] as String? ?? '',
        );
      }

      final timezone = data['timezone'] as String? ?? 'Asia/Kolkata';
      final timezoneOffset = (data['timezone_offset'] as num?)?.toInt() ?? 0;

      WeatherSummary _summaryFrom(dynamic weatherNode) {
        final first = (weatherNode as List?)?.first as Map<String, dynamic>?;
        return WeatherSummary(
          main: first?['main'] as String? ?? '',
          description: first?['description'] as String? ?? '',
          icon: first?['icon'] as String? ?? '',
        );
      }

      final currentRaw = data['current'] as Map<String, dynamic>?;
      if (currentRaw == null) return;

      final weatherCurrent = WeatherCurrent(
        dt: (currentRaw['dt'] as num?)?.toInt() ?? 0,
        temp: (currentRaw['temp'] as num?)?.toDouble() ?? 0.0,
        humidity: (currentRaw['humidity'] as num?)?.toInt() ?? 0,
        pressure: (currentRaw['pressure'] as num?)?.toInt() ?? 0,
        windSpeed: (currentRaw['wind_speed'] as num?)?.toDouble() ?? 0.0,
        uvi: (currentRaw['uvi'] as num?)?.toDouble() ?? 0.0,
        clouds: (currentRaw['clouds'] as num?)?.toInt() ?? 0,
        visibility: (currentRaw['visibility'] as num?)?.toInt() ?? 0,
        summary: _summaryFrom(currentRaw['weather']),
      );

      final hourlyRaw = (data['hourly'] as List<dynamic>? ?? []).take(12).toList();
      final hourly = hourlyRaw.map((h) {
        final hm = h as Map<String, dynamic>;
        return WeatherHourly(
          dt: (hm['dt'] as num?)?.toInt() ?? 0,
          temp: (hm['temp'] as num?)?.toDouble() ?? 0.0,
          summary: _summaryFrom(hm['weather']),
        );
      }).toList();

      final dailyRaw = (data['daily'] as List<dynamic>? ?? []).take(7).toList();
      final daily = dailyRaw.map((d) {
        final dm = d as Map<String, dynamic>;
        final tempMap = dm['temp'] as Map<String, dynamic>? ?? {};
        return WeatherDaily(
          dt: (dm['dt'] as num?)?.toInt() ?? 0,
          dayTemp: (tempMap['day'] as num?)?.toDouble() ?? 0.0,
          minTemp: (tempMap['min'] as num?)?.toDouble() ?? 0.0,
          maxTemp: (tempMap['max'] as num?)?.toDouble() ?? 0.0,
          summary: _summaryFrom(dm['weather']),
        );
      }).toList();

      appData.weatherDetails = WeatherDetails(
        timezone: timezone,
        timezoneOffset: timezoneOffset,
        current: weatherCurrent,
        hourly: hourly,
        daily: daily,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[AppData] _loadWeather ERROR: $e\n$st');
    }
  }

  Future<void> _loadAlbums() async {
    try {
      // ignore: avoid_print
      print('[AppData] _loadAlbums: querying...');
      final snap = await FirebaseFirestore.instance
          .collection('albums')
          .where('public', isEqualTo: true)
          .limit(6)
          .get();
      // ignore: avoid_print
      print('[AppData] _loadAlbums: got ${snap.docs.length} docs');

      final albums = <AppAlbum>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final userId = d['userId'] as String? ?? '';
        final images = List<String>.from(d['images'] as List? ?? const []);
        final coverUrl = images.isNotEmpty
            ? await _resolveImage(userId, images.first)
            : '';

        albums.add(
          AppAlbum(
            id: doc.id,
            name: d['name'] as String? ?? 'Untitled Album',
            description: d['description'] as String? ?? '',
            userId: userId,
            images: images,
            updateDate: (d['updateDate'] as num?)?.toInt() ?? 0,
            coverUrl: coverUrl,
          ),
        );
      }

      albums.sort((a, b) => b.updateDate.compareTo(a.updateDate));
      appData.albums = albums;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AppData] _loadAlbums ERROR: $e\n$st');
    }
  }
}

final AppDataService appDataService = AppDataService();
