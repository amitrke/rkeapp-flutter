import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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
    final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    return doc.data();
  }

  Future<String> _resolveImage(String userId, String filename) async {
    if (filename.startsWith('http')) return filename;

    final lastDot = filename.lastIndexOf('.');
    final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
    final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
    final path = 'users/$userId/images/${base}_680x680.$ext';

    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (_) {
      return '';
    }
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
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load the post right now.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
            future: Future.wait(rawImages.map((image) => _resolveImage(userId, image))),
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blueAccent,
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
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (updateDate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(updateDate),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (intro.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        intro,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
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
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
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
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.65,
                          color: Colors.black87,
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
