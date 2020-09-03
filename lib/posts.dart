import 'package:RkeApp/models.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_sorted_list.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostsService {
  AlbumData album;

  PostsService() {
    album = new AlbumData();
    this.syncAlbum();
  }

  syncAlbum() async {
    final snapshot =
        await FirebaseDatabase.instance.reference().child('album').once();
    List uids = snapshot.value.keys.toList();
    for (final uid in uids) {
      List hCodes = snapshot.value[uid].keys.toList();
      for (final hCode in hCodes) {
        var imgObj = snapshot.value[uid][hCode];
        final ref = FirebaseStorage.instance.ref().child(imgObj['path']);
        var url = await ref.getDownloadURL();
        postService.album
            .addImage(new AlbumItem(imgObj['path'], hCode, uid, url));
      }
    }
  }
}

final PostsService postService = PostsService();
