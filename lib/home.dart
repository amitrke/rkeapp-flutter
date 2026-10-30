import 'package:rkeapp/all_posts.dart';
import 'package:rkeapp/models.dart';
import 'package:rkeapp/post_detail.dart';
import 'package:rkeapp/posts.dart';
import 'package:rkeapp/theme.dart';
import 'package:rkeapp/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatelessWidget {
  final VoidCallback? onOpenWeather;
  final VoidCallback? onOpenGallery;
  final void Function(AppAlbum album)? onOpenAlbum;

  const HomeWidget({
    super.key,
    this.onOpenWeather,
    this.onOpenGallery,
    this.onOpenAlbum,
  });

  void _openPost(BuildContext context, Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          initialTitle: post.title,
          initialAuthorName: post.authorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, appData, _) {
        if (appData.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (appData.error) {
          return ErrorState(
            message: 'Couldn\'t load today\'s posts and news. Check your connection.',
            onRetry: appDataService.reload,
          );
        }
        return RefreshIndicator(
          onRefresh: appDataService.reload,
          child: ListView(
            // Bottom padding leaves room for the extended FAB.
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, 96),
            children: [
              if (appData.todayWeather != null) ...[
                _WeatherChips(
                  today: appData.todayWeather!,
                  onTap: onOpenWeather,
                ),
                const SizedBox(height: Space.l),
              ],
              if (appData.events.isNotEmpty) ...[
                _EventsBlock(events: appData.events),
                const SizedBox(height: Space.xl),
              ],
              SectionHeader(
                'From the community',
                actionLabel: 'See all',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllPostsScreen()),
                ),
              ),
              const SizedBox(height: Space.xs),
              if (appData.posts.isEmpty)
                const InlineEmpty('No community posts yet.')
              else ...[
                _FeaturedPostCard(
                  post: appData.posts.first,
                  onTap: () => _openPost(context, appData.posts.first),
                ),
                for (final post in appData.posts.skip(1))
                  _PostRow(post: post, onTap: () => _openPost(context, post)),
              ],
              const SizedBox(height: Space.xl),
              const SectionHeader('News'),
              if (appData.news.isEmpty)
                const InlineEmpty('No news right now.')
              else
                for (final item in appData.news) _NewsRow(item: item),
              const SizedBox(height: Space.xl),
              SectionHeader(
                'From the gallery',
                actionLabel: 'See all',
                onAction: onOpenGallery,
              ),
              const SizedBox(height: Space.xs),
              _GalleryRow(
                albums: appData.albums,
                onOpenAlbum: (album) => onOpenAlbum != null
                    ? onOpenAlbum!(album)
                    : onOpenGallery?.call(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherChips extends StatelessWidget {
  final WeatherDay today;
  final VoidCallback? onTap;
  const _WeatherChips({required this.today, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        ActionChip(
          avatar: Icon(weatherIcon(today.icon), size: 18),
          label: Text('${today.temp.round()}° ${today.condition}'),
          tooltip: 'Open weather',
          onPressed: onTap,
        ),
      ],
    );
  }
}

/// Next event as a highlighted card, followed by the rest as compact rows.
class _EventsBlock extends StatelessWidget {
  final List<AppEvent> events;
  const _EventsBlock({required this.events});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final next = events.first;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      padding: const EdgeInsets.all(Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DateTile(next.date),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.name,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [eventWhen(next.date), if (next.description.isNotEmpty) next.description]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (events.length > 1) ...[
            const SizedBox(height: Space.s),
            Divider(height: Space.s, color: scheme.outlineVariant),
            for (final e in events.skip(1))
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        shortDate(e.date),
                        style: text.labelLarge?.copyWith(color: scheme.secondary),
                      ),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const _FeaturedPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = [post.authorName, relativeTime(post.updateDate)]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkThumb(post.imageUrl, radius: 0),
                  if (post.category.isNotEmpty)
                    Positioned(
                      left: Space.s,
                      top: Space.s,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.category.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, Space.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (post.intro.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      post.intro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: Space.xs),
                  Text(
                    meta,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const _PostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = [post.authorName, relativeTime(post.updateDate)]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.s),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s),
        child: Row(
          children: [
            NetworkThumb(post.imageUrl, width: 56, height: 56),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final NewsItem item;
  const _NewsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasLink = item.url.trim().isNotEmpty;
    final when = relativeTime(item.createdAt);
    return InkWell(
      onTap: hasLink ? () => openLink(context, item.url) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Space.s + 2),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkThumb(
              item.imageUrl,
              width: 56,
              height: 56,
              placeholderIcon: Icons.newspaper_outlined,
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (when.isNotEmpty)
                        Text(
                          when,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (hasLink) ...[
                        const SizedBox(width: Space.xs),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                          semanticLabel: 'Opens in browser',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryRow extends StatelessWidget {
  final List<AppAlbum> albums;
  final void Function(AppAlbum album) onOpenAlbum;
  const _GalleryRow({required this.albums, required this.onOpenAlbum});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) return const InlineEmpty('No albums yet.');
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.m),
        itemBuilder: (context, i) {
          final album = albums[i];
          return SizedBox(
            width: 128,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.m),
              onTap: () => onOpenAlbum(album),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetworkThumb(
                    album.coverUrl,
                    width: 128,
                    height: 128,
                    radius: Radii.m,
                    placeholderIcon: Icons.photo_library_outlined,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
