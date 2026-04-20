import 'gallery.dart';
import 'home.dart';
import 'models.dart';
import 'myposts.dart';
import 'posts.dart';
import 'weather.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'auth.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp _ = await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: kIsWeb ? 'AIzaSyAmDbGMOQoxr8LT_RP1O2DJqbHD40dj1Kg' : 'AIzaSyDd535g7OeDtyKiyIJ1hOlKt2xcgDSAnSE',
      appId: kIsWeb ? '1:473096260334:web:bc48f4e8eafe7c02a1c1ff' : '1:473096260334:ios:9663975b0f5208a0a1c1ff',
      messagingSenderId: '473096260334',
      projectId: 'rkeorg',
      authDomain: 'rkeorg.firebaseapp.com',
      databaseURL: 'https://rkeorg-default-rtdb.firebaseio.com',
      storageBucket: 'rkeorg.appspot.com',
    ),
  );

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
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RkeApp',
      home: const MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _selectedIndex = 0;

  static const List<String> _pageTitles = <String>[
    'Home',
    'My Posts',
    'Gallery',
    'Weather',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateFromDrawer(BuildContext context, int index) {
    Navigator.of(context).pop();
    if (_selectedIndex != index) {
      _onItemTapped(index);
    }
  }

  Future<void> _handleAccountAction(BuildContext context, RkeUser user) async {
    Navigator.of(context).pop();
    if (user.uid.isNotEmpty) {
      await authService.signOut();
      return;
    }

    if (!kIsWeb && Platform.isIOS) {
      await _showSignInSheet(context);
    } else {
      await authService.googleSignIn();
    }
  }

  Future<void> _showSignInSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in with Google'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final signedInUser = await authService.googleSignIn();
                if (!context.mounted || signedInUser != null) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google sign-in failed. Please try again.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Sign in with Apple'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final signedInUser = await authService.appleSignIn();
                if (!context.mounted || signedInUser != null) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Apple sign-in failed. Verify Sign in with Apple in Apple/Firebase config and try again.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(RkeUser user) {
    if (user.uid.isNotEmpty) {
      return UserAccountsDrawerHeader(
        margin: EdgeInsets.zero,
        accountName: Text(user.name.isNotEmpty ? user.name : 'Guest'),
        accountEmail: Text(
          user.email.isNotEmpty ? user.email : 'Welcome to Roorkee',
        ),
        currentAccountPicture: CircleAvatar(
          backgroundImage: NetworkImage(user.photoURL),
        ),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline, color: Colors.blueAccent, size: 30),
          ),
          SizedBox(height: 14),
          Text(
            'Welcome to Roorkee',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Sign in to upload photos and access your posts.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blue.shade50,
      selectedColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => _navigateFromDrawer(context, index),
    );
  }

  Widget navigate(BuildContext context, int index) {
    if (index == 0) {
      return HomeWidget(
        onOpenWeather: () => _onItemTapped(3),
        onOpenGallery: () => _onItemTapped(2),
        onOpenAlbum: (album) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(album: album),
            ),
          );
        },
      );
    } else if (index == 1) {
      return const MyPostsWidget();
    } else if (index == 2) {
      return const PhotoGalleryScreen();
    } else {
      return const WeatherDetailsWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context, listen: true);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(user),
              const SizedBox(height: 8),
              _buildDrawerItem(
                context: context,
                index: 0,
                icon: Icons.home,
                title: 'Home',
              ),
              _buildDrawerItem(
                context: context,
                index: 1,
                icon: Icons.account_box,
                title: 'My Posts',
              ),
              _buildDrawerItem(
                context: context,
                index: 2,
                icon: Icons.photo_library,
                title: 'Gallery',
              ),
              _buildDrawerItem(
                context: context,
                index: 3,
                icon: Icons.wb_sunny,
                title: 'Weather',
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  user.uid.isNotEmpty ? Icons.logout : Icons.login,
                ),
                title: Text(user.uid.isNotEmpty ? 'Logout' : 'Login'),
                onTap: () => _handleAccountAction(context, user),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.blueAccent,
      ),
      body: navigate(context, _selectedIndex),
      floatingActionButton: _selectedIndex == 1 && user.uid != ''
          ? FloatingActionButton(
              onPressed: () => MyPostsWidget.filePicker(context, user),
              tooltip: 'Add Photo',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
