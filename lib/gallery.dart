import 'package:rkeapp/collections.dart';
import 'package:rkeapp/image_utils.dart';
import 'package:rkeapp/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhotoGalleryScreen extends StatelessWidget {
  const PhotoGalleryScreen({super.key});

  static Future<List<AppAlbum>> fetchAlbums() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(Collections.albums)
        .where('public', isEqualTo: true)
        .where('approved', isEqualTo: true)
        .get();

    final futures = snapshot.docs.map((doc) async {
      final data = doc.data();
      final userId = data['userId'] as String? ?? '';
      final images = List<String>.from(data['images'] as List? ?? const []);
      final coverUrl = images.isNotEmpty
          ? await resolveStorageImage(userId, images.first, size: 's')
          : '';

      return AppAlbum(
        id: doc.id,
        name: data['name'] as String? ?? 'Untitled Album',
        description: data['description'] as String? ?? '',
        userId: userId,
        images: images,
        updateDate: (data['updateDate'] as num?)?.toInt() ?? 0,
        coverUrl: coverUrl,
      );
    });

    final albums = await Future.wait(futures);
    albums.sort((a, b) => b.updateDate.compareTo(a.updateDate));
    return albums;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppAlbum>>(
      future: fetchAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load photo albums right now.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final albums = snapshot.data ?? const <AppAlbum>[];
        if (albums.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No albums available yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 900
                ? 4
                : width > 600
                    ? 3
                    : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo Gallery',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${albums.length} ${albums.length == 1 ? 'album' : 'albums'} available',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(album: album),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: album.coverUrl.isNotEmpty
                                    ? Image.network(
                                        album.coverUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.photo_library_outlined,
                                            color: Colors.grey,
                                            size: 42,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.photo_library_outlined,
                                          color: Colors.grey,
                                          size: 42,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      album.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${album.images.length} ${album.images.length == 1 ? 'photo' : 'photos'}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (album.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        album.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  final AppAlbum album;

  const AlbumDetailScreen({super.key, required this.album});

  Future<List<String>> _loadImages(String size) async {
    final futures = album.images
        .map((image) => resolveStorageImage(album.userId, image, size: size))
        .toList();
    final urls = await Future.wait<String>(futures);
    return urls.where((url) => url.isNotEmpty).toList();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog.fullscreen(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<String>>(
        future: _loadImages('m'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final images = snapshot.data ?? const <String>[];
          if (images.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This album has no photos to display.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return FutureBuilder<List<String>>(
            future: _loadImages('l'),
            builder: (context, largeSnapshot) {
              final largeImages = largeSnapshot.data ?? images;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (album.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        album.description,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${album.images.length} ${album.images.length == 1 ? 'photo' : 'photos'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final previewUrl = images[index];
                        final fullUrl = index < largeImages.length
                            ? largeImages[index]
                            : previewUrl;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showFullImage(context, fullUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              previewUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
