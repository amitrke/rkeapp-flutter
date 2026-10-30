import 'dart:async';

import 'collections.dart';
import 'create_album.dart';
import 'create_post.dart';
import 'models.dart';
import 'sign_in.dart';
import 'theme.dart';
import 'widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _AccountTab { posts, albums, alerts }

/// The "You" tab — profile, the user's own posts and albums (with moderation
/// status), and unread notifications. Sign out and account deletion live in
/// Settings.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

/// Firestore streams for one user. Counts and lists get separate streams
/// (each is single-subscription); Firestore shares the underlying listener.
class _UserStreams {
  final String uid;
  final Stream<QuerySnapshot> postsCount, albumsCount, alertsCount;
  final Stream<QuerySnapshot> posts, albums, alerts;

  _UserStreams._(this.uid, Query p, Query a, Query n)
      : postsCount = p.snapshots(),
        albumsCount = a.snapshots(),
        alertsCount = n.snapshots(),
        posts = p.snapshots(),
        albums = a.snapshots(),
        alerts = n.snapshots();

  factory _UserStreams(String uid) {
    final db = FirebaseFirestore.instance;
    return _UserStreams._(
      uid,
      db.collection(Collections.posts).where('userId', isEqualTo: uid),
      db.collection(Collections.albums).where('userId', isEqualTo: uid),
      db
          .collection(Collections.notifications)
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true),
    );
  }
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  _AccountTab _tab = _AccountTab.posts;
  _UserStreams? _streams;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<RkeUser>(context);

    if (user.uid.isEmpty) {
      _streams = null;
      return EmptyState(
        icon: Icons.person_outline,
        message: 'Sign in to share posts and albums with the Roorkee community.',
        actionLabel: 'Sign in',
        onAction: () => startSignIn(context),
      );
    }

    if (_streams?.uid != user.uid) _streams = _UserStreams(user.uid);
    final streams = _streams!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.m),
          child: Column(
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: Space.l),
              Row(
                children: [
                  _CountTile(stream: streams.postsCount, label: 'Posts'),
                  const SizedBox(width: Space.s),
                  _CountTile(stream: streams.albumsCount, label: 'Albums'),
                  const SizedBox(width: Space.s),
                  _CountTile(stream: streams.alertsCount, label: 'Alerts'),
                ],
              ),
              const SizedBox(height: Space.m),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_AccountTab>(
                  segments: const [
                    ButtonSegment(value: _AccountTab.posts, label: Text('Posts')),
                    ButtonSegment(value: _AccountTab.albums, label: Text('Albums')),
                    ButtonSegment(value: _AccountTab.alerts, label: Text('Alerts')),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _AccountTab.posts => _MyPostsTab(userId: user.uid, stream: streams.posts),
            _AccountTab.albums => _MyAlbumsTab(userId: user.uid, stream: streams.albums),
            _AccountTab.alerts => _NotificationsTab(stream: streams.alerts),
          },
        ),
      ],
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final RkeUser user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          backgroundImage:
              user.photoURL.isNotEmpty ? NetworkImage(user.photoURL) : null,
          child: user.photoURL.isEmpty
              ? Text(initial, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.isNotEmpty ? user.name : 'Roorkee member',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (user.email.isNotEmpty)
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  const _CountTile({required this.stream, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.m),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            final count = snap.data?.docs.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count?.toString() ?? '–',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Shared row ───────────────────────────────────────────────────────────────

class _ContentRow extends StatelessWidget {
  final Widget thumb;
  final String title;
  final String status;
  final String meta;
  final VoidCallback onTap;

  const _ContentRow({
    required this.thumb,
    required this.title,
    required this.status,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final untitled = title.isEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        child: Row(
          children: [
            thumb,
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    untitled ? 'Untitled draft' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontStyle: untitled ? FontStyle.italic : null,
                      color: untitled ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      StatusBadge(status),
                      const SizedBox(width: Space.s),
                      Expanded(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

String _joinMeta(List<String> parts) =>
    parts.where((s) => s.isNotEmpty).join(' · ');

// ─── My Posts tab ─────────────────────────────────────────────────────────────

class _MyPostsTab extends StatelessWidget {
  final String userId;
  final Stream<QuerySnapshot> stream;
  const _MyPostsTab({required this.userId, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return const ErrorState(message: 'Couldn\'t load your posts. Check your connection.');
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.article_outlined,
            message: 'No posts yet.\nTap New post to share your first one.',
          );
        }

        final posts = docs
            .map((d) =>
                MyUserPost.fromDoc(d.id, d.data() as Map<String, dynamic>))
            .toList();
        posts.sort((a, b) => b.updateDate.compareTo(a.updateDate));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            return _ContentRow(
              thumb: post.images.isNotEmpty
                  ? _StorageThumb(userId: userId, filename: post.images.first)
                  : const NetworkThumb('', width: 48, height: 48,
                      placeholderIcon: Icons.article_outlined),
              title: post.title,
              status: post.status,
              meta: _joinMeta([capitalize(post.category), relativeTime(post.updateDate)]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(postId: post.id, userId: userId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── My Albums tab ────────────────────────────────────────────────────────────

class _MyAlbumsTab extends StatelessWidget {
  final String userId;
  final Stream<QuerySnapshot> stream;
  const _MyAlbumsTab({required this.userId, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return const ErrorState(message: 'Couldn\'t load your albums. Check your connection.');
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.photo_album_outlined,
            message: 'No albums yet.',
            actionLabel: 'Create an album',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateAlbumScreen(userId: userId)),
            ),
          );
        }

        final albums = docs
            .map((d) =>
                MyUserAlbum.fromDoc(d.id, d.data() as Map<String, dynamic>))
            .toList();
        albums.sort((a, b) => b.updateDate.compareTo(a.updateDate));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final album = albums[i];
            final count = album.images.length;
            return _ContentRow(
              thumb: album.images.isNotEmpty
                  ? _StorageThumb(userId: userId, filename: album.images.first)
                  : const NetworkThumb('', width: 48, height: 48,
                      placeholderIcon: Icons.photo_album_outlined),
              title: album.name,
              status: album.status,
              meta: _joinMeta([
                '$count photo${count == 1 ? '' : 's'}',
                relativeTime(album.updateDate),
              ]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateAlbumScreen(albumId: album.id, userId: userId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 200×200 variant of a user's uploaded image.
class _StorageThumb extends StatelessWidget {
  final String userId;
  final String filename;
  const _StorageThumb({required this.userId, required this.filename});

  String get _url {
    final lastDot = filename.lastIndexOf('.');
    final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
    final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
    final path = 'users/$userId/images/${base}_200x200.$ext';
    final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
    return 'https://storage.googleapis.com/rkeorg.appspot.com/$encodedPath';
  }

  @override
  Widget build(BuildContext context) {
    return NetworkThumb(_url, width: 48, height: 48);
  }
}

// ─── Notifications tab ────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  const _NotificationsTab({required this.stream});

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
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none_outlined,
            message: 'You\'re all caught up.\nWe\'ll let you know when a post or album is reviewed.',
          );
        }

        final notifs = docs
            .map((d) => UserNotification.fromDoc(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${notifs.length} unread',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  TextButton(
                    onPressed: () =>
                        _markAllRead(notifs.map((n) => n.id).toList()),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: notifs.length,
                itemBuilder: (context, i) => _NotifRow(
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

class _NotifRow extends StatelessWidget {
  final UserNotification notif;
  final VoidCallback onRead;
  const _NotifRow({required this.notif, required this.onRead});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isApproved = notif.type == 'approved';
    final kind = notif.itemType == 'post' ? 'Post' : 'Album';
    final hasReason = !isApproved && notif.rejectionReason != null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isApproved ? scheme.successContainer : scheme.errorContainer,
        child: Icon(
          isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isApproved ? scheme.onSuccessContainer : scheme.onErrorContainer,
        ),
      ),
      title: Text(
        isApproved ? '$kind published' : '$kind not approved',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${notif.itemTitle}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasReason)
            Text(
              'Reason: ${notif.rejectionReason}',
              style: TextStyle(color: scheme.error),
              maxLines: 2,
            ),
        ],
      ),
      isThreeLine: hasReason,
      trailing: TextButton(
        onPressed: onRead,
        child: const Text('Dismiss'),
      ),
    );
  }
}
