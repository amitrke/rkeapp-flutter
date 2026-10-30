import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

// ─── Formatting helpers ───────────────────────────────────────────────────────

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// "Just now", "3h ago", "2 days ago", or "4 Oct 2025" for older dates.
String relativeTime(int epochMillis) {
  if (epochMillis <= 0) return '';
  final then = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  final diff = DateTime.now().difference(then);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${then.day} ${_months[then.month - 1]} ${then.year}';
}

/// "Sunday · in 9 days" for an ISO date string; empty if unparseable.
String eventWhen(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  final today = DateUtils.dateOnly(DateTime.now());
  final days = DateUtils.dateOnly(date).difference(today).inDays;
  final weekday = _weekdays[date.weekday - 1];
  if (days == 0) return '$weekday · today';
  if (days == 1) return '$weekday · tomorrow';
  return '$weekday · in $days days';
}

/// "Nov 8" for an ISO date string.
String shortDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  return date == null ? '' : '${_months[date.month - 1]} ${date.day}';
}

/// "7 pm", "6:10 pm" — Indian English clock style.
String clockLabel(DateTime t, {bool minutes = false}) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final suffix = t.hour < 12 ? 'am' : 'pm';
  if (!minutes && t.minute == 0) return '$h $suffix';
  return '$h:${t.minute.toString().padLeft(2, '0')} $suffix';
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Maps an OpenWeatherMap icon code (e.g. "10n") to a Material icon.
IconData weatherIcon(String code) {
  final night = code.endsWith('n');
  final group = code.length >= 2 ? code.substring(0, 2) : '';
  switch (group) {
    case '01':
      return night ? Icons.nightlight_outlined : Icons.wb_sunny_outlined;
    case '02':
      return night ? Icons.nights_stay_outlined : Icons.wb_cloudy_outlined;
    case '03':
    case '04':
      return Icons.cloud_outlined;
    case '09':
    case '10':
      return Icons.water_drop_outlined;
    case '11':
      return Icons.thunderstorm_outlined;
    case '13':
      return Icons.ac_unit;
    case '50':
      return Icons.foggy;
    default:
      return Icons.wb_sunny_outlined;
  }
}

/// Opens a link in an in-app browser tab. Returns false if it could not open.
Future<bool> openLink(BuildContext context, String rawUrl) async {
  final trimmed = rawUrl.trim();
  final withScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (trimmed.isEmpty || uri == null || uri.host.isEmpty) return false;
  final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Couldn\'t open this link. Check your connection and try again.')),
    );
  }
  return launched;
}

// ─── Layout pieces ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Rounded network image with a tonal placeholder for missing or broken URLs.
class NetworkThumb extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final IconData placeholderIcon;

  const NetworkThumb(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = Radii.s,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: scheme.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Marigold month/day tile used for events and holidays.
class DateTile extends StatelessWidget {
  final String isoDate;
  const DateTile(this.isoDate, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(isoDate);
    final month = date == null ? '?' : _months[date.month - 1].toUpperCase();
    final day = date == null ? '?' : date.day.toString().padLeft(2, '0');
    return Semantics(
      label: date == null ? null : '${_months[date.month - 1]} ${date.day}',
      excludeSemantics: true,
      child: Container(
        width: 52,
        height: 56,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(Radii.s + 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month,
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              day,
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moderation status ('draft' | 'pending' | 'published') with icon + tonal fill,
/// so it never relies on color alone.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String label;
    switch (status) {
      case 'published':
        bg = scheme.successContainer;
        fg = scheme.onSuccessContainer;
        icon = Icons.check_circle_outline;
        label = 'Published';
        break;
      case 'pending':
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        icon = Icons.schedule;
        label = 'In review';
        break;
      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        icon = Icons.edit_note;
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 8, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: Space.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: Space.l),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

/// Inline empty message used inside a section (not full-screen).
class InlineEmpty extends StatelessWidget {
  final String message;
  const InlineEmpty(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.l),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
