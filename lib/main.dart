import 'content_safety.dart';
import 'create_post.dart';
import 'gallery.dart';
import 'home.dart';
import 'models.dart';
import 'myposts.dart';
import 'posts.dart';
import 'settings.dart';
import 'sign_in.dart';
import 'theme.dart';
import 'weather.dart';
import 'widgets.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAmDbGMOQoxr8LT_RP1O2DJqbHD40dj1Kg',
          appId: '1:473096260334:web:bc48f4e8eafe7c02a1c1ff',
          messagingSenderId: '473096260334',
          projectId: 'rkeorg',
          authDomain: 'rkeorg.firebaseapp.com',
          databaseURL: 'https://rkeorg-default-rtdb.firebaseio.com',
          storageBucket: 'rkeorg.appspot.com',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid:
          kReleaseMode
              ? const AndroidPlayIntegrityProvider()
              : const AndroidDebugProvider(),
      providerApple:
          kReleaseMode
              ? const AppleDeviceCheckProvider()
              : const AppleDebugProvider(
                  // Token is injected via --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>
                  // Register the uuid at: Firebase Console → App Check →
                  // Apps → RkeApp (iOS) → Manage debug tokens
                  debugToken: String.fromEnvironment('APP_CHECK_DEBUG_TOKEN'),
                ),
    );
  }

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<RkeUser>.value(value: authService.rkeUser),
    ChangeNotifierProvider<AppData>.value(value: appDataService.appData),
    ChangeNotifierProvider<BlockList>.value(value: blockList),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RkeApp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  MyStatefulWidgetState createState() => MyStatefulWidgetState();
}

/// Root shell: bottom navigation between Home, Gallery, Weather and You.
class MyStatefulWidgetState extends State<MyStatefulWidget> {
  static const int _home = 0;
  static const int _gallery = 1;
  static const int _weather = 2;
  static const int _you = 3;

  int _selectedIndex = _home;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _body(BuildContext context) {
    switch (_selectedIndex) {
      case _gallery:
        return const PhotoGalleryScreen();
      case _weather:
        return const WeatherDetailsWidget();
      case _you:
        return const MyAccountScreen();
      default:
        return HomeWidget(
          onOpenWeather: () => _onItemTapped(_weather),
          onOpenGallery: () => _onItemTapped(_gallery),
          onOpenAlbum: (album) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(album: album),
              ),
            );
          },
        );
    }
  }

  PreferredSizeWidget _appBar(BuildContext context, RkeUser user) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    switch (_selectedIndex) {
      case _gallery:
        return AppBar(title: const Text('Gallery'));
      case _weather:
        return AppBar(
          title: const Text('Weather'),
          actions: [
            Consumer<AppData>(
              builder: (context, appData, _) {
                final details = appData.weatherDetails;
                if (details == null || details.current.dt == 0) {
                  return const SizedBox.shrink();
                }
                final updated = DateTime.fromMillisecondsSinceEpoch(
                  (details.current.dt + details.timezoneOffset) * 1000,
                  isUtc: true,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: Space.l),
                  child: Text(
                    'Updated ${clockLabel(updated, minutes: true)}',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ],
        );
      case _you:
        return AppBar(
          title: const Text('You'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        );
      default:
        return AppBar(
          title: Text(
            'Roorkee',
            style: text.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: IconButton(
                tooltip: user.uid.isNotEmpty ? 'Your profile' : 'Sign in',
                onPressed: () => user.uid.isNotEmpty
                    ? _onItemTapped(_you)
                    : startSignIn(context),
                icon: _Avatar(user: user),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context, listen: true);
    final showFab = user.uid.isNotEmpty &&
        (_selectedIndex == _home || _selectedIndex == _you);

    return Scaffold(
      appBar: _appBar(context, user),
      body: _body(context),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(userId: user.uid),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New post'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_cloudy_outlined),
            selectedIcon: Icon(Icons.wb_cloudy),
            label: 'Weather',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final RkeUser user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signedIn = user.uid.isNotEmpty;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '';
    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: signedIn && user.photoURL.isNotEmpty
          ? NetworkImage(user.photoURL)
          : null,
      child: signedIn && user.photoURL.isEmpty && initial.isNotEmpty
          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w700))
          : signedIn && user.photoURL.isNotEmpty
              ? null
              : const Icon(Icons.person_outline, size: 18),
    );
  }
}
