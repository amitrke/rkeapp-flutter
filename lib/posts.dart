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
        .then((value) => {print(value)});
  }

  syncAlbum() {}
}

final PostsService postService = PostsService();
