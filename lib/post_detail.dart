import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'collections.dart' show Collections;
import 'image_utils.dart' show resolveStorageImage;
import 'package:flutter/material.dart';
import 'widgets.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String initialTitle;
  final String initialAuthorName;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.initialTitle,
    required this.initialAuthorName,
  });

  Future<Map<String, dynamic>?> _loadPost() async {
    final doc = await FirebaseFirestore.instance.collection(Collections.posts).doc(postId).get();
    return doc.data();
  }

  String _extractBodyText(String? edState) {
    if (edState == null || edState.isEmpty) return '';
    try {
      final decoded = jsonDecode(edState) as Map<String, dynamic>;
      final blocks = (decoded['blocks'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      final lines = blocks
          .map((block) => (block['text'] as String? ?? '').trim())
          .where((text) => text.isNotEmpty)
          .toList();
      return lines.join('\n\n');
    } catch (_) {
      return '';
    }
  }

  String _formatDate(int millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialTitle),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const ErrorState(
              message: 'Couldn\'t load this post. Check your connection.',
            );
          }

          final post = snapshot.data!;
          final title = post['title'] as String? ?? initialTitle;
          final intro = post['intro'] as String? ?? '';
          final category = post['category'] as String? ?? '';
          final userId = post['userId'] as String? ?? '';
          final updateDate = (post['updateDate'] as num?)?.toInt() ?? 0;
          final body = _extractBodyText(post['edState'] as String?);
          final rawImages = List<String>.from(post['images'] as List? ?? const []);

          return FutureBuilder<List<String>>(
            future: Future.wait(rawImages.map((image) => resolveStorageImage(userId, image))),
            builder: (context, imageSnapshot) {
              final imageUrls = (imageSnapshot.data ?? const <String>[])
                  .where((url) => url.isNotEmpty)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By $initialAuthorName',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (updateDate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(updateDate),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (intro.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        intro,
                        style: TextStyle(
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                imageUrls[index],
                                width: 300,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 300,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Story',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.65,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
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
