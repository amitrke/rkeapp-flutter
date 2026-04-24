import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'collections.dart';
import 'gallery.dart';
import 'models.dart';
import 'post_detail.dart';

/// Public profile page for any user.
class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  Future<_ProfileData> _load() async {
    final userDoc = await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(userId)
        .get();
    final userData = userDoc.data() ?? {};

    final postsSnap = await FirebaseFirestore.instance
        .collection(Collections.posts)
        .where('userId', isEqualTo: userId)
        .where('public', isEqualTo: true)
        .where('approved', isEqualTo: true)
        .orderBy('updateDate', descending: true)
        .get();

    final albumsSnap = await FirebaseFirestore.instance
        .collection(Collections.albums)
        .where('userId', isEqualTo: userId)
        .where('public', isEqualTo: true)
        .where('approved', isEqualTo: true)
        .orderBy('updateDate', descending: true)
        .get();

    // Resolve album cover URLs
    final albumFutures = albumsSnap.docs.map((doc) async {
      final d = doc.data();
      final uid = d['userId'] as String? ?? '';
      final images = List<String>.from(d['images'] as List? ?? []);
      String coverUrl = '';
      if (images.isNotEmpty) {
        try {
          coverUrl = await PhotoGalleryScreen.resolveImage(uid, images.first, size: 's');
        } catch (_) {}
      }
      return AppAlbum(
        id: doc.id,
        name: d['name'] as String? ?? '',
        description: d['description'] as String? ?? '',
        userId: uid,
        images: images,
        updateDate: d['updateDate'] as int? ?? 0,
        coverUrl: coverUrl,
      );
    });

    return _ProfileData(
      name: userData['name'] as String? ?? '',
      profilePic: userData['profilePic'] as String? ?? '',
      posts: postsSnap.docs,
      albums: await Future.wait(albumFutures),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<_ProfileData>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Could not load profile.'));
          }
          final data = snap.data!;
          return _ProfileBody(data: data);
        },
      ),
    );
  }
}

class _ProfileData {
  final String name;
  final String profilePic;
  final List<QueryDocumentSnapshot> posts;
  final List<AppAlbum> albums;

  _ProfileData({
    required this.name,
    required this.profilePic,
    required this.posts,
    required this.albums,
  });
}

class _ProfileBody extends StatelessWidget {
  final _ProfileData data;
  const _ProfileBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: Colors.blueAccent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: data.profilePic.isNotEmpty
                      ? NetworkImage(data.profilePic)
                      : null,
                  backgroundColor: Colors.white,
                  child: data.profilePic.isEmpty
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.blueAccent)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  data.name.isNotEmpty ? data.name : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (data.posts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Posts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...data.posts.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _PostRow(postId: doc.id, data: d);
            }),
          ],
          if (data.albums.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Albums',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...data.albums.map((album) => _AlbumRow(album: album)),
          ],
          if (data.posts.isEmpty && data.albums.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No public posts or albums yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;
  const _PostRow({required this.postId, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '(Untitled)';
    final intro = data['intro'] as String? ?? '';
    final authorName = data['authorName'] as String? ?? '';
    return ListTile(
      leading: const Icon(Icons.article_outlined, color: Colors.blueGrey),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: intro.isNotEmpty
          ? Text(intro, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: postId,
            initialTitle: title,
            initialAuthorName: authorName,
          ),
        ));
      },
    );
  }
}

class _AlbumRow extends StatelessWidget {
  final AppAlbum album;
  const _AlbumRow({required this.album});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: album.coverUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                album.coverUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.photo_library_outlined, size: 40),
              ),
            )
          : const Icon(Icons.photo_library_outlined, size: 40),
      title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${album.images.length} photo${album.images.length == 1 ? '' : 's'}'),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(album: album),
        ));
      },
    );
  }
}
