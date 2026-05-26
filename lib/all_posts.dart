import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'collections.dart';
import 'post_detail.dart';
import 'user_profile.dart';

/// Paginated, filterable list of all published posts.
class AllPostsScreen extends StatefulWidget {
  const AllPostsScreen({super.key});

  @override
  State<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  static const _categories = [
    'All',
    'Town',
    'Blog',
    'Recipe',
    'Event',
    'News',
    'Business',
  ];
  static const _pageSize = 10;

  String _selectedCategory = 'All';
  final List<QueryDocumentSnapshot> _docs = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  // Cache author names to avoid re-fetching
  final Map<String, String> _authorCache = {};

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Query<Map<String, dynamic>> get _query {
    var q = FirebaseFirestore.instance
        .collection(Collections.posts)
        .where('public', isEqualTo: true)
        .where('approved', isEqualTo: true)
        .orderBy('updateDate', descending: true)
        .limit(_pageSize);

    if (_selectedCategory != 'All') {
      q = q.where('category', isEqualTo: _selectedCategory);
    }
    return q;
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      Query<Map<String, dynamic>> q = _query;
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

      final snap = await q.get();
      if (snap.docs.length < _pageSize) _hasMore = false;
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      setState(() => _docs.addAll(snap.docs));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeCategory(String category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    _loadMore();
  }

  Future<String> _authorName(String userId) async {
    if (_authorCache.containsKey(userId)) return _authorCache[userId]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(userId)
          .get();
      final name = doc.data()?['name'] as String? ?? userId;
      _authorCache[userId] = name;
      return name;
    } catch (_) {
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Posts')),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => _changeCategory(cat),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Posts list
          Expanded(
            child: _docs.isEmpty && !_loading
                ? const Center(
                    child: Text(
                      'No posts found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _docs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _docs.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: _loading
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: _loadMore,
                                    child: const Text('Load more'),
                                  ),
                          ),
                        );
                      }
                      return _PostCard(
                        doc: _docs[i],
                        authorNameFuture: _authorName(
                          (_docs[i].data() as Map<String, dynamic>)['userId']
                                  as String? ??
                              '',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Future<String> authorNameFuture;

  const _PostCard({required this.doc, required this.authorNameFuture});

  String _thumbUrl(String userId, String filename) {
    final lastDot = filename.lastIndexOf('.');
    final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
    final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
    final path = 'users/$userId/images/${base}_200x200.$ext';
    final encoded = path.split('/').map(Uri.encodeComponent).join('/');
    return 'https://storage.googleapis.com/rkeorg.appspot.com/$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final title = d['title'] as String? ?? '(Untitled)';
    final intro = d['intro'] as String? ?? '';
    final category = d['category'] as String? ?? '';
    final userId = d['userId'] as String? ?? '';
    final images = List<String>.from(d['images'] as List? ?? []);
    final thumbUrl = images.isNotEmpty ? _thumbUrl(userId, images.first) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FutureBuilder<String>(
              future: authorNameFuture,
              builder: (ctx, snap) => PostDetailScreen(
                postId: doc.id,
                initialTitle: title,
                initialAuthorName: snap.data ?? '',
              ),
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumbUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    thumbUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                )
              else
                _placeholder(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                              fontSize: 11, color: Colors.blue.shade700),
                        ),
                      ),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (intro.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        intro,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: authorNameFuture,
                      builder: (context, snap) {
                        final name = snap.data ?? '';
                        return GestureDetector(
                          onTap: userId.isNotEmpty
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserProfileScreen(userId: userId),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            name.isNotEmpty ? 'by $name' : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.article_outlined, color: Colors.grey, size: 32),
    );
  }
}
