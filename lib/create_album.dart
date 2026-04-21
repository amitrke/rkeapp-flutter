import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Create or edit an album.
///
/// Pass [albumId] and [userId] to edit an existing album; leave [albumId] null
/// to create a new one.
class CreateAlbumScreen extends StatefulWidget {
  final String? albumId;
  final String userId;

  const CreateAlbumScreen({super.key, this.albumId, required this.userId});

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<String> _images = []; // stored as base filenames (no size suffix)
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.albumId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('albums')
          .doc(widget.albumId)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _nameCtrl.text = d['name'] as String? ?? '';
        _descCtrl.text = d['description'] as String? ?? '';
        _images = List<String>.from(d['images'] as List? ?? []);
      }
    }
    setState(() => _loading = false);
  }

  // ─── Image upload ────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    for (final pf in result.files) {
      if (pf.path != null) {
        await _uploadImage(File(pf.path!));
      }
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _saving = true);
    try {
      final original = p.basenameWithoutExtension(file.path)
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w]'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = '$original-$timestamp';
      final storedName = '$baseName.$ext';

      // Resize to max 680px
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Could not decode image');

      img.Image resized;
      if (decoded.width > decoded.height) {
        resized = img.copyResize(decoded, width: 680);
      } else {
        resized = img.copyResize(decoded, height: 680);
      }
      final resizedBytes = img.encodeJpg(resized, quality: 85);

      final storagePath =
          'users/${widget.userId}/images/${baseName}_680x680.$ext';
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putData(
        resizedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

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
      final col = FirebaseFirestore.instance.collection('albums');
      final now = DateTime.now().millisecondsSinceEpoch;
      final name = _nameCtrl.text.trim();

      final data = <String, dynamic>{
        'name': name,
        'description': _descCtrl.text.trim(),
        'images': _images,
        'public': publish,
        'userId': widget.userId,
        'updateDate': now,
      };

      String docId;
      if (widget.albumId != null) {
        await col.doc(widget.albumId).update(data);
        docId = widget.albumId!;
      } else {
        data['createDate'] = now;
        data['approved'] = false;
        final ref = await col.add(data);
        docId = ref.id;
      }

      if (publish) {
        await FirebaseFirestore.instance
            .collection('moderationQueue')
            .doc(docId)
            .set({
          'itemId': docId,
          'itemType': 'album',
          'userId': widget.userId,
          'status': 'pending',
          'submittedAt': now,
          'reviewedAt': null,
          'reviewedBy': null,
          'rejectionReason': null,
          'title': name,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish
                ? 'Album submitted for review!'
                : 'Draft saved.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving album: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.albumId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Album' : 'Create Album'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
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
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Album Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Photos section
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
                          icon:
                              const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Photos'),
                          onPressed: _saving ? null : _pickAndUploadImages,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_images.isEmpty)
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No photos yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, i) => _AlbumImageThumb(
                          userId: widget.userId,
                          filename: _images[i],
                          onRemove: () => _removeImage(i),
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

// ─── Image thumbnail in grid ──────────────────────────────────────────────────

class _AlbumImageThumb extends StatelessWidget {
  final String userId;
  final String filename;
  final VoidCallback onRemove;

  const _AlbumImageThumb({
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
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
