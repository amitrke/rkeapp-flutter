import 'package:rkeapp/all_posts.dart';
import 'package:rkeapp/models.dart';
import 'package:rkeapp/post_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Uri? _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final withScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);

    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  Future<void> _openNewsLink(BuildContext context, String rawUrl) async {
    final uri = _normalizeUrl(rawUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid link is available for this news item.')),
      );
      return;
    }

    // Show confirmation before opening in browser
    if (!context.mounted) return;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open in Browser'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will open the following link in your browser:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                uri.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldOpen) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link right now.')),
      );
    }
  }

  void _showFullImagePreview(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog.fullscreen(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load content. Please check your connection and restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 20),
              if (appData.todayWeather != null) ...[
                _buildWeatherSection(appData),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Recent Posts'),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllPostsScreen()),
                    ),
                    child: const Text('View all →'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPostsRow(appData.posts),
              const SizedBox(height: 24),
              _buildSectionHeader('Latest News'),
              const SizedBox(height: 8),
              _buildNewsRow(appData.news),
              const SizedBox(height: 24),
              _buildSectionHeader('Upcoming Events'),
              const SizedBox(height: 8),
              _buildEventsList(appData.events),
              const SizedBox(height: 24),
              _buildGalleryHeader(),
              const SizedBox(height: 8),
              _buildGalleryRow(appData.albums),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Roorkee',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            'Your community hub for Roorkee town news, events, and stories.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(AppData appData) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onOpenWeather,
      child: Row(
        children: [
          if (appData.todayWeather != null)
            Expanded(child: _weatherCard('Today', appData.todayWeather!)),
          if (appData.tomorrowWeather != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _weatherCard('Tomorrow', appData.tomorrowWeather!)),
          ],
        ],
      ),
    );
  }

  Widget _weatherCard(String label, WeatherDay w) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            if (w.icon.isNotEmpty)
              Image.network(
                'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_sunny, size: 40, color: Colors.orange),
              ),
            Text('${w.temp.round()}°C',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(w.condition,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildGalleryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From the Gallery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'Tap album, or long-press image for fullscreen',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        TextButton(
          onPressed: onOpenGallery,
          child: const Text('View all'),
        ),
      ],
    );
  }

  Widget _buildPostsRow(List<Post> posts) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No posts yet.', style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildPostCard(posts[i]),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return SizedBox(
      width: 180,
      child: Builder(
        builder: (context) {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    postId: post.id,
                    initialTitle: post.title,
                    initialAuthorName: post.authorName,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardImage(post.imageUrl),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('By ${post.authorName}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          post.intro.length > 60
                              ? '${post.intro.substring(0, 60)}...'
                              : post.intro,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsRow(List<NewsItem> news) {
    if (news.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No news available.', style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: news.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildNewsCard(news[i]),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    return SizedBox(
      width: 180,
      child: Builder(
        builder: (context) {
          final hasLink = _normalizeUrl(item.url) != null;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: hasLink ? () => _openNewsLink(context, item.url) : null,
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardImage(item.imageUrl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              item.description.length > 80
                                  ? '${item.description.substring(0, 80)}...'
                                  : item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          if (hasLink) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Open in browser',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 100,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return Image.network(
      imageUrl,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 100,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildEventsList(List<AppEvent> events) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No upcoming events.', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: events.map(_buildEventTile).toList(),
    );
  }

  Widget _buildEventTile(AppEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(event.formattedMonth,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text(event.formattedDay,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        title:
            Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: event.description.isNotEmpty
            ? Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
      ),
    );
  }

  Widget _buildGalleryRow(List<AppAlbum> albums) {
    if (albums.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No albums yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final album = albums[i];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (onOpenAlbum != null) {
                onOpenAlbum!(album);
                return;
              }
              onOpenGallery?.call();
            },
            onLongPress: album.coverUrl.isNotEmpty
                ? () => _showFullImagePreview(context, album.coverUrl)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  SizedBox(
                    width: 130,
                    height: 150,
                    child: album.coverUrl.isNotEmpty
                        ? Image.network(
                            album.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
