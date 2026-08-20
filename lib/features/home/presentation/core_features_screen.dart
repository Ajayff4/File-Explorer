import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoreFeaturesScreen extends StatelessWidget {
  const CoreFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Core features'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 2 : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * _cardSpacing) /
                        columns;
                return Wrap(
                  spacing: _cardSpacing,
                  runSpacing: _cardSpacing,
                  children: [
                    for (final feature in _coreFeatures)
                      SizedBox(
                        width: cardWidth,
                        child: _CoreFeatureCard(feature: feature),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _cardSpacing = 10.0;

class _CoreFeatureCard extends StatefulWidget {
  const _CoreFeatureCard({required this.feature});

  final _CoreFeature feature;

  @override
  State<_CoreFeatureCard> createState() => _CoreFeatureCardState();
}

class _CoreFeatureCardState extends State<_CoreFeatureCard> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    final colorScheme = Theme.of(context).colorScheme;

    return NeumorphicCard(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox.square(
                  dimension: 46,
                  child: Icon(feature.icon, color: feature.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature.description,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoreFeature {
  const _CoreFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

const _coreFeatures = [
  _CoreFeature(
    icon: Icons.download_rounded,
    title: 'Universal Downloader',
    description:
        'Paste a YouTube, Instagram, Twitter, or other media link and download it as video or audio with yt-dlp, queue, progress/speed, retry, and concurrent download limits.',
    color: Color(0xFFD81B60),
  ),
  _CoreFeature(
    icon: Icons.folder_open_rounded,
    title: 'Storage browser',
    description:
        'Browse internal storage with breadcrumbs, list/grid views, sorting, type filters, and badge counts.',
    color: Color(0xFF7C3AED),
  ),
  _CoreFeature(
    icon: Icons.photo_library_rounded,
    title: 'Media libraries',
    description:
        'Browse grouped images, videos, audio, documents, apps, and archives with grid or list view and sort options.',
    color: Color(0xFFEC407A),
  ),
  _CoreFeature(
    icon: Icons.play_circle_fill_rounded,
    title: 'Built-in viewers',
    description:
        'View images, play videos with double-tap seek and mute, listen to audio, read text and code files, and open any file with system apps or force-open as a specific type — including files inside ZIP archives.',
    color: Color(0xFF26A69A),
  ),
  _CoreFeature(
    icon: Icons.sync_alt_rounded,
    title: 'Transfer Station',
    description:
        'Queue copy, move, rename, delete, retry, and conflict handling with progress.',
    color: Color(0xFF1E88E5),
  ),
  _CoreFeature(
    icon: Icons.inventory_2_rounded,
    title: 'Archive tools',
    description:
        'Browse ZIP contents in-app and preview images, video, audio, and text inside archives; compress ZIP, TAR, GZ, and TAR.GZ with level and password options and extract them.',
    color: Color(0xFF8D6E63),
  ),
  _CoreFeature(
    icon: Icons.search_rounded,
    title: 'Search',
    description:
        'Search current folders or storage root with type filters and a persisted index.',
    color: Color(0xFFFFB300),
  ),
  _CoreFeature(
    icon: Icons.star_rounded,
    title: 'Favorites and recents',
    description: 'Keep important folders and recent locations ready on Home.',
    color: Color(0xFFE53935),
  ),
  _CoreFeature(
    icon: Icons.info_outline_rounded,
    title: 'File details',
    description:
        'Inspect single or selected items with folder size computation, combined counts, and common path.',
    color: Color(0xFF43A047),
  ),
  _CoreFeature(
    icon: Icons.tune_rounded,
    title: 'Settings',
    description: 'Tune Explorer, transfer, search, history, and Home behavior.',
    color: Color(0xFF7E57C2),
  ),
];
