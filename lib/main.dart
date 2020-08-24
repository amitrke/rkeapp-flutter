import 'package:RkeApp/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<RkeUser>.value(value: authService.rkeUserStream)
      ],
      child: MaterialApp(
        title: 'RkeApp Login',
        home: Scaffold(
          appBar: AppBar(
              title: Text('RkeApp'),
              backgroundColor: Colors.amber
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[LoginButton(), UserProfile()],
            ),
          ),
        ),
      )
    );
  }
}

class UserProfile extends StatefulWidget {
  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  String _name;
  bool _loading = false;
  String fileName = '';

  @override
  Widget build(BuildContext context) {
    final rkeUser = Provider.of<RkeUser>(context); // gets the firebase user
    if (rkeUser != null){
      _name = rkeUser.name;
    } else {
      _name = "";
    }
    return Column(children: <Widget>[
      Container(padding: EdgeInsets.all(20), child: Text('Hi ${_name}!')),
      ListTile(
        title: Text('Image', style: TextStyle(color: Colors.white),),
        leading: Icon(Icons.image, color: Colors.redAccent,),
        onTap: () {
          filePicker(context);
        },
      )
    ]);
  }

  Future filePicker(BuildContext context) async {
    try {
        File file = await FilePicker.getFile();
        print(file.path);
      }
      catch(e){
        print(e);
      }
    }
}

class LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: authService.user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MaterialButton(
              onPressed: () => authService.signOut(),
              color: Colors.red,
              textColor: Colors.white,
              child: Text('Signout'),
            );
          } else {
            return MaterialButton(
              onPressed: () => authService.googleSignIn(),
              color: Colors.white,
              textColor: Colors.black,
              child: Text('Login with Google'),
            );
          }
        });
  }
}