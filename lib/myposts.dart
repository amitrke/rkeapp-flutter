import 'dart:io';

import 'package:RkeApp/auth.dart';
import 'package:RkeApp/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as Img;

class MyPostsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rkeUser = Provider.of<RkeUser>(context); // gets the firebase user

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(padding: EdgeInsets.all(20), child: firstLine(rkeUser)),
          loginLogoutButton(rkeUser)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => filePicker(context, rkeUser),
        tooltip: 'Add Photo',
        child: const Icon(Icons.add),
      ),
    );
  }

  firstLine(RkeUser user) {
    if (user != null && user.uid != "") {
      return Text('Hi ${user.name}!');
    } else {
      return Text('Please login !');
    }
  }

  loginLogoutButton(RkeUser user) {
    if (user != null && user.uid != "") {
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
  }

  Future filePicker(BuildContext context, RkeUser rkeUser) async {
    try {
      File file = await FilePicker.getFile();
      String fileUrl =
          await _uploadFile(file, p.basename(file.path), rkeUser.uid);
      String uploadStatus = "Failed to upload file !";
      if (fileUrl != "") {
        uploadStatus = "File uploaded successfully !";
      }
      final snackBar = SnackBar(content: Text(uploadStatus));
      Scaffold.of(context).showSnackBar(snackBar);
    } catch (e) {
      print(e);
      final snackBar = SnackBar(content: Text("Something went wrong :("));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Future<String> _uploadFile(File file, String filename, String uid) async {
    final FirebaseStorage _storage =
        FirebaseStorage(storageBucket: 'gs://myrke-189201.appspot.com');
    StorageReference storageReference =
        _storage.ref().child("users/$uid/$filename");
    Img.Image imageTemp = Img.decodeImage(file.readAsBytesSync());
    Img.Image resizedImg = Img.copyResize(imageTemp, height: 768);
    var compressedImage = new File(file.path)
      ..writeAsBytesSync(Img.encodeJpg(resizedImg, quality: 85));
    final StorageUploadTask uploadTask =
        storageReference.putFile(compressedImage);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
    await updateFileDbEntry(
        uid, filename, downloadUrl.ref.hashCode, downloadUrl.ref.path);
    print("URL is $url");
    return url;
  }

  updateFileDbEntry(
      String uid, String filename, int hashCode, String path) async {
    FirebaseDatabase.instance
        .reference()
        .child('album')
        .child(uid)
        .child(hashCode.toString())
        .set({'path': path, 'filename': filename});
  }
}
