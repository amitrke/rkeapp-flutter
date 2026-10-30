import 'package:rkeapp/collections.dart';
import 'package:rkeapp/image_utils.dart';
import 'package:rkeapp/models.dart';
import 'package:rkeapp/theme.dart';
import 'package:rkeapp/widgets.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FutureBuilder<List<AppAlbum>>(
      future: fetchAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const ErrorState(
            message: 'Couldn\'t load photo albums. Check your connection.',
          );
        }

        final albums = snapshot.data ?? const <AppAlbum>[];
        if (albums.isEmpty) {
          return const EmptyState(
            icon: Icons.photo_library_outlined,
            message: 'No albums yet.',
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

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.xl),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: Space.m,
                mainAxisSpacing: Space.l,
                childAspectRatio: 0.8,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final count = album.images.length;
                return InkWell(
                  borderRadius: BorderRadius.circular(Radii.m),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(album: album),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: NetworkThumb(
                          album.coverUrl,
                          width: double.infinity,
                          radius: Radii.m,
                          placeholderIcon: Icons.photo_library_outlined,
                        ),
                      ),
                      const SizedBox(height: Space.s),
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$count ${count == 1 ? 'photo' : 'photos'}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              },
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
      ),
      body: FutureBuilder<List<String>>(
        future: _loadImages('m'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final images = snapshot.data ?? const <String>[];
          if (images.isEmpty) {
            return const EmptyState(
              icon: Icons.photo_outlined,
              message: 'This album has no photos yet.',
            );
          }

          return FutureBuilder<List<String>>(
            future: _loadImages('l'),
            builder: (context, largeSnapshot) {
              final largeImages = largeSnapshot.data ?? images;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (album.description.isNotEmpty) ...[
                      Text(
                        album.description,
                        style: text.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: Space.s),
                    ],
                    Text(
                      '${album.images.length} ${album.images.length == 1 ? 'photo' : 'photos'} · tap a photo to view full screen',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: Space.l),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: Space.s,
                        mainAxisSpacing: Space.s,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final previewUrl = images[index];
                        final fullUrl = index < largeImages.length
                            ? largeImages[index]
                            : previewUrl;
                        return InkWell(
                          borderRadius: BorderRadius.circular(Radii.s),
                          onTap: () => _showFullImage(context, fullUrl),
                          child: Semantics(
                            label: 'Photo ${index + 1} of ${images.length}',
                            button: true,
                            child: NetworkThumb(previewUrl, radius: Radii.s),
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
