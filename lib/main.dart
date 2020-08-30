import 'package:RkeApp/home.dart';
import 'package:RkeApp/models.dart';
import 'package:RkeApp/myposts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp();
  final FirebaseStorage storage = FirebaseStorage(
      app: app, storageBucket: 'gs://myrke-189201.appspot.com');
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<RkeUser>.value(value: authService.rkeUser),
      ],
      child: MyApp(storage: storage))
  );
}

class MyApp extends StatelessWidget {
  final FirebaseStorage storage;
  MyApp({this.storage});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'RkeApp Login',
        home: MyStatefulWidget(),
      );
  }
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home',
      style: optionStyle,
    ),
    Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  navigate(int index){
    if (index == 0){
      return HomeWidget();
    }
    else if (index == 1) {
      return MyPostsWidget();
    }
    else {
      return _widgetOptions.elementAt(_selectedIndex);
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
              backgroundImage: NetworkImage(Provider.of<RkeUser>(context, listen: true).photoURL),
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
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            title: Text('MyPosts'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_friendly),
            title: Text('LocalAds'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
