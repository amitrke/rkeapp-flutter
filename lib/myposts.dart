import 'dart:io';

import 'auth.dart';
import 'models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    if (user.uid != "") {
      return Text('Hi ${user.name}!');
    } else {
      return Text('Please login !');
    }
  }

  loginLogoutButton(RkeUser user) {
    if (user.uid != "") {
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
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      String fileUrl =
          await _uploadFile(file, p.basename(file.path), rkeUser.uid);
      String uploadStatus = "Failed to upload file !";
      if (fileUrl != "") {
        uploadStatus = "File uploaded successfully !";
      }
      final snackBar = SnackBar(content: Text(uploadStatus));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      print(e);
      final snackBar = SnackBar(content: Text("Something went wrong :("));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<String> _uploadFile(File file, String filename, String uid) async {
    final FirebaseStorage storage =
      FirebaseStorage.instanceFor(bucket: 'gs://rkeorg.appspot.com');
    final Reference storageReference =
        storage.ref().child("users/$uid/$filename");
    final Img.Image? imageTemp = Img.decodeImage(file.readAsBytesSync());
    if (imageTemp == null) return "";
    final Img.Image resizedImg = Img.copyResize(imageTemp, height: 768);
    var compressedImage = new File(file.path)
      ..writeAsBytesSync(Img.encodeJpg(resizedImg, quality: 85));
    final UploadTask uploadTask = storageReference.putFile(compressedImage);
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    final String url = await snapshot.ref.getDownloadURL();
    await updateFileDbEntry(
        uid, filename, snapshot.ref.hashCode, snapshot.ref.fullPath);
    print("URL is $url");
    return url;
  }

  updateFileDbEntry(
      String uid, String filename, int hashCode, String path) async {
    final db = FirebaseDatabase.instance.ref();
    await db
        .child('album')
        .child(uid)
        .child(hashCode.toString())
        .set({'path': path, 'filename': filename});
  }
}
