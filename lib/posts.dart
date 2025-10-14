import 'models.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostsService {
  AlbumData album = AlbumData();

  PostsService() {
    this.syncAlbum();
  }

  syncAlbum() async {
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('album').get();
    if (!snapshot.exists) return;
    final albumData = snapshot.value as Map<dynamic, dynamic>;
    final uids = albumData.keys.toList();
    for (final uid in uids) {
      final userAlbum = (albumData[uid] as Map<dynamic, dynamic>);
      for (final entry in userAlbum.entries) {
        final hCode = entry.key.toString();
        final imgObj = entry.value as Map<dynamic, dynamic>;
        final ref = FirebaseStorage.instance.ref().child(imgObj['path'] as String);
        final url = await ref.getDownloadURL();
        postService.album
            .addImage(AlbumItem(imgObj['path'] as String, hCode, uid as String, url));
      }
    }
  }
}

final PostsService postService = PostsService();
