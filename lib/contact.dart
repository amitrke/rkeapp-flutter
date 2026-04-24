import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'collections.dart';
import 'models.dart';

/// Contact form — logged-in users send a message to the site admins.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyCtrl = TextEditingController();

  String _reason = 'General';
  bool _sending = false;
  bool _sent = false;

  static const _reasons = [
    'General',
    'Post an advertisement',
    'Contribute as developer',
    'Report an issue',
  ];

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection(Collections.messages).add({
        'fromUserId': userId,
        'title': _reason,
        'body': _bodyCtrl.text.trim(),
        'updateDate': DateTime.now().millisecondsSinceEpoch,
        'toUserId': '0',
        'state': 'unread',
        'thread': '',
      });
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user.uid.isEmpty
            ? _buildSignedOut()
            : _sent
                ? _buildSuccess()
                : _buildForm(user.uid),
      ),
    );
  }

  Widget _buildSignedOut() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please sign in to send a message.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 72, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Message sent!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for reaching out. We will get back to you soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(String userId) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _reason = v);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(
              labelText: 'Message *',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Message is required' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sending ? null : () => _submit(userId),
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}
