import 'home.dart';
import 'models.dart';
import 'myposts.dart';
import 'posts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp _ = kIsWeb
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAmDbGMOQoxr8LT_RP1O2DJqbHD40dj1Kg',
            appId: '1:473096260334:web:bc48f4e8eafe7c02a1c1ff',
            messagingSenderId: '473096260334',
            projectId: 'rkeorg',
            authDomain: 'rkeorg.firebaseapp.com',
            databaseURL: 'https://rkeorg-default-rtdb.firebaseio.com',
            storageBucket: 'rkeorg.appspot.com',
          ),
        )
      : await Firebase.initializeApp();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget navigate(int index) {
    if (index == 0) {
      return const HomeWidget();
    } else {
      return MyPostsWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RkeApp'),
        backgroundColor: Colors.blueAccent,
        actions: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.indigo,
            child: CircleAvatar(
              radius: 22,
        backgroundImage: NetworkImage(
          Provider.of<RkeUser>(context, listen: true).photoURL),
            ),
          )
        ],
      ),
      body: Center(
        child: navigate(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: 'MyPosts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_friendly),
            label: 'LocalAds',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber,
        onTap: _onItemTapped,
      ),
    );
  }
}
