import 'package:RkeApp/models.dart';
import 'package:firebase_database/firebase_database.dart';

class PostsService {
  AlbumData album;

  PostsService() {
    album = new AlbumData();
    FirebaseDatabase.instance
        .reference()
        .child('album')
        .once()
        .then((DataSnapshot snapshot) {
      List uids = snapshot.value.keys.toList();
      uids.forEach((uid) {
        List hCodes = snapshot.value[uid].keys.toList();
        hCodes.forEach((hcode) {
          var imgObj = snapshot.value[uid][hcode];
          print(imgObj);
          postService.album.addImage(new AlbumItem(imgObj['path'], hcode, uid));
        });
      });
      print('Connected to second database andread ${snapshot.value}');
    }).catchError((onError) {
      print('Error $onError');
    });
  }

  syncAlbum() {}
}

final PostsService postService = PostsService();
