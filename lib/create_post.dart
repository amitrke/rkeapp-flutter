import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'collections.dart' show Collections;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'image_utils.dart' show resizeAndUploadImage;

/// Create or edit a post.
///
/// Pass [postId] and [userId] to edit an existing post; leave [postId] null to
/// create a new one.
class CreatePostScreen extends StatefulWidget {
  final String? postId;
  final String userId;

  const CreatePostScreen({super.key, this.postId, required this.userId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _category = 'town';
  List<String> _images = []; // stored as base filenames (no size suffix)
  bool _loading = true;
  bool _saving = false;

  static const _categories = [
    'town', 'blog', 'recipe', 'event', 'news', 'business'
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _introCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.postId != null) {
      final doc = await FirebaseFirestore.instance
          .collection(Collections.posts)
          .doc(widget.postId)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _titleCtrl.text = d['title'] as String? ?? '';
        _introCtrl.text = d['intro'] as String? ?? '';
        _category = d['category'] as String? ?? 'town';
        _images = List<String>.from(d['images'] as List? ?? []);
        // Parse Draft.js edState → plain text
        final edState = d['edState'] as String? ?? '';
        if (edState.isNotEmpty) {
          try {
            final decoded = jsonDecode(edState) as Map<String, dynamic>;
            final blocks = decoded['blocks'] as List? ?? [];
            _bodyCtrl.text =
                blocks.map((b) => b['text'] as String? ?? '').join('\n');
          } catch (_) {
            _bodyCtrl.text = edState;
          }
        }
      }
    }
    setState(() => _loading = false);
  }

  // ─── Slug ────────────────────────────────────────────────────────────────

  String _buildSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  // ─── Draft.js JSON ───────────────────────────────────────────────────────

  String _buildEdState(String body) {
    final lines = body.split('\n');
    final blocks = lines.asMap().entries.map((e) {
      return {
        'key': 'b${e.key}',
        'text': e.value,
        'type': 'unstyled',
        'depth': 0,
        'inlineStyleRanges': <dynamic>[],
        'entityRanges': <dynamic>[],
        'data': <String, dynamic>{},
      };
    }).toList();
    return jsonEncode({'blocks': blocks, 'entityMap': <String, dynamic>{}});
  }

  // ─── Image upload ────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    await _uploadImage(file);
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _saving = true);
    try {
      final storedName = await resizeAndUploadImage(file, widget.userId);
      setState(() => _images.add(storedName));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ─── Save ────────────────────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    await _save(publish: false);
  }

  Future<void> _submitForReview() async {
    if (!_formKey.currentState!.validate()) return;
    await _save(publish: true);
  }

  Future<void> _save({required bool publish}) async {
    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance.collection(Collections.posts);
      final now = DateTime.now().millisecondsSinceEpoch;
      final title = _titleCtrl.text.trim();
      final slug = _buildSlug(title);
      final edState = _buildEdState(_bodyCtrl.text);

      final data = <String, dynamic>{
        'title': title,
        'intro': _introCtrl.text.trim(),
        'category': _category,
        'edState': edState,
        'images': _images,
        'public': publish,
        'userId': widget.userId,
        'slug': slug,
        'updateDate': now,
      };

      String docId;
      if (widget.postId != null) {
        await col.doc(widget.postId).update(data);
        docId = widget.postId!;
      } else {
        data['createDate'] = now;
        data['approved'] = false;
        final ref = await col.add(data);
        docId = ref.id;
      }

      if (publish) {
        // Write to moderationQueue so admins can review
        await FirebaseFirestore.instance
            .collection(Collections.moderationQueue)
            .doc(docId)
            .set({
          'itemId': docId,
          'itemType': 'post',
          'userId': widget.userId,
          'status': 'pending',
          'submittedAt': now,
          'reviewedAt': null,
          'reviewedBy': null,
          'rejectionReason': null,
          'title': title,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish
                ? 'Post submitted for review!'
                : 'Draft saved.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          if (_saving) const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Intro / excerpt
                    TextFormField(
                      controller: _introCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Intro / Excerpt',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c[0].toUpperCase() + c.substring(1),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Body
                    TextFormField(
                      controller: _bodyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Body *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 14,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Body is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Images section
                    Row(
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Photo'),
                          onPressed: _saving ? null : _pickAndUploadImage,
                        ),
                      ],
                    ),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) =>
                              _ImageThumb(
                            userId: widget.userId,
                            filename: _images[i],
                            onRemove: () => _removeImage(i),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _saveDraft,
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _submitForReview,
                            child: const Text('Submit for Review'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Image thumbnail widget ───────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final String userId;
  final String filename;
  final VoidCallback onRemove;

  const _ImageThumb({
    required this.userId,
    required this.filename,
    required this.onRemove,
  });

  String get _url {
    final lastDot = filename.lastIndexOf('.');
    final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
    final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
    final path = 'users/$userId/images/${base}_200x200.$ext';
    final encoded = path.split('/').map(Uri.encodeComponent).join('/');
    return 'https://storage.googleapis.com/rkeorg.appspot.com/$encoded';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
