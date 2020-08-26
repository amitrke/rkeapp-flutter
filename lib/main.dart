import 'package:RkeApp/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

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
        home: Scaffold(
          appBar: AppBar(
              title: Text(Provider.of<RkeUser>(context, listen: true).name),
              backgroundColor: Colors.amber
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[LoginButton(), UserProfile()],
            ),
          ),
        ),
      );
  }
}

class UserProfile extends StatefulWidget {
  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  String _name;
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
      Container(padding: EdgeInsets.all(20), child: Text('Hi $_name!')),
      ListTile(
        title: Text('Image', style: TextStyle(color: Colors.white),),
        leading: Icon(Icons.image, color: Colors.redAccent,),
        onTap: () {
          filePicker(context, rkeUser);
        },
      )
    ]);
  }

  Future filePicker(BuildContext context, RkeUser rkeUser) async {
    try {
        File file = await FilePicker.getFile();
        print(file.path);
        _uploadFile(file, p.basename(file.path), rkeUser.uid);
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

Future<String> _uploadFile(File file, String filename, String uid) async {
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://myrke-189201.appspot.com');
  StorageReference storageReference = _storage.ref().child("users/$uid/$filename");
  final StorageUploadTask uploadTask = storageReference.putFile(file);
  final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
  final String url = (await downloadUrl.ref.getDownloadURL());
  print("URL is $url");
  return url;
}