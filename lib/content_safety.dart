import 'dart:async';

import 'collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The signed-in user's block list, kept in sync with users/{uid}/blocked.
/// Screens that list other users' content filter it through [isBlocked].
class BlockList with ChangeNotifier {
  Set<String> _blockedIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  BlockList() {
    FirebaseAuth.instance.authStateChanges().listen(_onUserChanged);
  }

  bool isBlocked(String userId) => _blockedIds.contains(userId);

  void _onUserChanged(User? user) {
    _subscription?.cancel();
    _subscription = null;
    _blockedIds = {};
    notifyListeners();
    if (user == null) return;

    _subscription = _blockedCollection(user.uid).snapshots().listen(
      (snap) {
        _blockedIds = snap.docs.map((doc) => doc.id).toSet();
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  CollectionReference<Map<String, dynamic>> _blockedCollection(String uid) {
    return FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(uid)
        .collection(Collections.blocked);
  }

  Future<void> block(String userId, String userName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || userId.isEmpty || userId == uid) return;
    await _blockedCollection(uid).doc(userId).set({
      'name': userName,
      'blockedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> unblock(String userId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _blockedCollection(uid).doc(userId).delete();
  }
}

final BlockList blockList = BlockList();

const List<String> reportReasons = [
  'Spam or misleading',
  'Harassment or hate speech',
  'Sexual or violent content',
  'Illegal activity',
  'Other',
];

Future<void> reportContent({
  required String itemId,
  required String itemType,
  required String itemTitle,
  required String itemOwnerId,
  required String reason,
  required String details,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Sign in to report content.');
  }
  await FirebaseFirestore.instance.collection(Collections.reports).add({
    'itemId': itemId,
    'itemType': itemType,
    'itemTitle': itemTitle,
    'itemOwnerId': itemOwnerId,
    'reporterId': uid,
    'reason': reason,
    'details': details,
    'status': 'open',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  });
}

/// App bar overflow menu offering Report and Block/Unblock for another
/// user's post or album. Renders nothing on the viewer's own content.
class ContentActionsMenu extends StatelessWidget {
  final String itemId;
  final String itemType; // 'post' | 'album'
  final String itemTitle;
  final String ownerId;
  final String ownerName;

  const ContentActionsMenu({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId.isEmpty || ownerId == currentUid) {
      return const SizedBox.shrink();
    }
    final blocked = context.watch<BlockList>().isBlocked(ownerId);

    return PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (value) {
        if (currentUid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to report or block content.')),
          );
          return;
        }
        switch (value) {
          case 'report':
            _showReportDialog(context);
          case 'block':
            _confirmBlock(context);
          case 'unblock':
            _unblock(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('Report $itemType'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: blocked ? 'unblock' : 'block',
          child: ListTile(
            leading: Icon(blocked ? Icons.check_circle_outline : Icons.block),
            title: Text(blocked ? 'Unblock user' : 'Block user'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  String get _displayName => ownerName.isNotEmpty ? ownerName : 'this user';

  Future<void> _showReportDialog(BuildContext context) async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => _ReportDialog(
        itemId: itemId,
        itemType: itemType,
        itemTitle: itemTitle,
        ownerId: ownerId,
      ),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thanks for reporting. Our moderators will review it within 24 hours.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $_displayName?'),
        content: const Text(
          "You won't see their posts or albums anymore. You can unblock them from their content or profile.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await blockList.block(ownerId, ownerName);
      messenger.showSnackBar(
        SnackBar(content: Text('Blocked $_displayName.')),
      );
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not block this user: $e')),
      );
    }
  }

  Future<void> _unblock(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await blockList.unblock(ownerId);
      messenger.showSnackBar(
        SnackBar(content: Text('Unblocked $_displayName.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not unblock this user: $e')),
      );
    }
  }
}

class _ReportDialog extends StatefulWidget {
  final String itemId;
  final String itemType;
  final String itemTitle;
  final String ownerId;

  const _ReportDialog({
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.ownerId,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _reason = reportReasons.first;
  final _detailsCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await reportContent(
        itemId: widget.itemId,
        itemType: widget.itemType,
        itemTitle: widget.itemTitle,
        itemOwnerId: widget.ownerId,
        reason: _reason,
        details: _detailsCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Could not send the report: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.itemType}'),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _reason,
          onChanged: (value) {
            if (value != null) setState(() => _reason = value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final reason in reportReasons)
                RadioListTile<String>(
                  value: reason,
                  title: Text(reason),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Report'),
        ),
      ],
    );
  }
}
