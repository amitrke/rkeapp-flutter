import 'dart:async';

import 'auth.dart';
import 'collections.dart';
import 'create_album.dart';
import 'create_post.dart';
import 'models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Account tab — shows profile info, the user's own posts and albums
/// (with moderation status badges), and unread notifications.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context);

    if (user.uid.isEmpty) {
      return _buildSignedOut(context);
    }

    return Column(
      children: [
        _ProfileHeader(
          user: user,
          deletingAccount: _deletingAccount,
          onDeleteAccount: _deletingAccount
              ? null
              : () => _confirmDeleteAccount(user),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
            Tab(icon: Icon(Icons.photo_album_outlined), text: 'Albums'),
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Alerts'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MyPostsTab(userId: user.uid),
              _MyAlbumsTab(userId: user.uid),
              _NotificationsTab(userId: user.uid),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount(RkeUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          user.email.isNotEmpty
              ? 'This permanently deletes $user.email, including your profile, posts, albums, notifications, and uploaded photos. This cannot be undone.'
              : 'This permanently deletes your profile, posts, albums, notifications, and uploaded photos. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deletingAccount = true);
    final result = await authService.deleteCurrentUserAccount();
    if (!mounted) {
      return;
    }

    setState(() => _deletingAccount = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.deleted ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sign in to manage your posts and albums',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              onPressed: () => authService.googleSignIn(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final RkeUser user;
  final bool deletingAccount;
  final VoidCallback? onDeleteAccount;

  const _ProfileHeader({
    required this.user,
    required this.deletingAccount,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: user.photoURL.isNotEmpty
                    ? NetworkImage(user.photoURL)
                    : null,
                backgroundColor: Colors.white,
                child: user.photoURL.isEmpty
                    ? const Icon(Icons.person, color: Colors.blueAccent, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.email.isNotEmpty)
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                tooltip: 'Sign out',
                onPressed: deletingAccount ? null : () => authService.signOut(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDeleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: deletingAccount
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                deletingAccount ? 'Deleting account...' : 'Delete Account',
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This removes your app account and associated data.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── My Posts tab ─────────────────────────────────────────────────────────────

class _MyPostsTab extends StatelessWidget {
  final String userId;
  const _MyPostsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(Collections.posts)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline,
            message: 'Unable to load your posts right now.',
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.article_outlined,
            message: 'No posts yet.\nTap + to create your first post.',
          );
        }

        final posts = docs
            .map((d) =>
                MyUserPost.fromDoc(d.id, d.data() as Map<String, dynamic>))
            .toList();
        posts.sort((a, b) => b.updateDate.compareTo(a.updateDate));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _PostCard(post: posts[i], userId: userId),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final MyUserPost post;
  final String userId;
  const _PostCard({required this.post, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text(
          post.title.isNotEmpty ? post.title : '(Untitled)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            _CategoryChip(post.category),
            const SizedBox(width: 6),
            _StatusBadge(post.status),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CreatePostScreen(postId: post.id, userId: userId),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── My Albums tab ────────────────────────────────────────────────────────────

class _MyAlbumsTab extends StatelessWidget {
  final String userId;
  const _MyAlbumsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(Collections.albums)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline,
            message: 'Unable to load your albums right now.',
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.photo_album_outlined,
            message: 'No albums yet.\nCreate your first album!',
          );
        }

        final albums = docs
            .map((d) =>
                MyUserAlbum.fromDoc(d.id, d.data() as Map<String, dynamic>))
            .toList();
        albums.sort((a, b) => b.updateDate.compareTo(a.updateDate));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: albums.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _AlbumCard(album: albums[i], userId: userId),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final MyUserAlbum album;
  final String userId;
  const _AlbumCard({required this.album, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: album.images.isNotEmpty
            ? _AlbumThumb(userId: userId, filename: album.images.first)
            : const Icon(Icons.photo_album_outlined, size: 40),
        title: Text(
          album.name.isNotEmpty ? album.name : '(Untitled)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '${album.images.length} photo${album.images.length == 1 ? "" : "s"}',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(width: 6),
            _StatusBadge(album.status),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CreateAlbumScreen(albumId: album.id, userId: userId),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumThumb extends StatefulWidget {
  final String userId;
  final String filename;
  const _AlbumThumb({required this.userId, required this.filename});

  @override
  State<_AlbumThumb> createState() => _AlbumThumbState();
}

class _AlbumThumbState extends State<_AlbumThumb> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _buildUrl();
  }

  void _buildUrl() {
    final lastDot = widget.filename.lastIndexOf('.');
    final base = lastDot != -1
        ? widget.filename.substring(0, lastDot)
        : widget.filename;
    final ext =
        lastDot != -1 ? widget.filename.substring(lastDot + 1) : '';
    final path = 'users/${widget.userId}/images/${base}_200x200.$ext';
    final encodedPath =
        path.split('/').map(Uri.encodeComponent).join('/');
    setState(() {
      _url =
          'https://storage.googleapis.com/rkeorg.appspot.com/$encodedPath';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return const SizedBox(width: 40, height: 40);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        _url!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }
}

// ─── Notifications tab ────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final String userId;
  const _NotificationsTab({required this.userId});

  Future<void> _markRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection(Collections.notifications)
        .doc(notifId)
        .update({'read': true});
  }

  Future<void> _markAllRead(List<String> ids) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.update(
          FirebaseFirestore.instance.collection(Collections.notifications).doc(id),
          {'read': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(Collections.notifications)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.notifications_none_outlined,
            message: 'No new notifications.',
          );
        }

        final notifs = docs
            .map((d) => UserNotification.fromDoc(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${notifs.length} unread',
                      style: const TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () =>
                        _markAllRead(notifs.map((n) => n.id).toList()),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _NotifCard(
                    notif: notifs[i],
                    onRead: () => _markRead(notifs[i].id)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotifCard extends StatelessWidget {
  final UserNotification notif;
  final VoidCallback onRead;
  const _NotifCard({required this.notif, required this.onRead});

  @override
  Widget build(BuildContext context) {
    final isApproved = notif.type == 'approved';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isApproved ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isApproved
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: isApproved ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          isApproved
              ? "${notif.itemType == 'post' ? 'Post' : 'Album'} approved"
              : "${notif.itemType == 'post' ? 'Post' : 'Album'} not approved",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${notif.itemTitle}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isApproved && notif.rejectionReason != null)
              Text(
                'Reason: ${notif.rejectionReason}',
                style:
                    const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
              ),
          ],
        ),
        isThreeLine: !isApproved && notif.rejectionReason != null,
        trailing: TextButton(
          onPressed: onRead,
          child: const Text('Dismiss'),
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'published':
        color = Colors.green;
        label = 'Published';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  @override
  Widget build(BuildContext context) {
    return Text(
      category.isNotEmpty
          ? category[0].toUpperCase() + category.substring(1)
          : '',
      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
