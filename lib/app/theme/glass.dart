import 'dart:ui';

import 'package:flutter/material.dart';

/// Holographic blue reserved for chrome accents (nav edge). Surfaces stay
/// neutral so glowing icon chips carry the color story.
const Color _holoBlue = Color(0xFF2563EB);

/// Glassmorphism primitives: thick frosted-glass blocks over an ambient
/// gradient backdrop (see [GlassAmbientBackground], mounted once in
/// `AppShell`).
///
/// The 3D "thick glass" read comes from four layered cues (no extra blurs,
/// so it stays cheap):
/// 1. Directional edge-light — the 1px rim is a gradient, bright top-left
///    fading to dim bottom-right, like light catching a real edge.
/// 2. Specular streak — a soft diagonal sheen sweeping the face.
/// 3. Inner depth — bright inner top, dark inner bottom (thickness).
/// 4. Drop shadow + optional accent outer glow (selected/hero surfaces).
///
/// Real [BackdropFilter] blur lives only on [GlassCard]/chrome — dense
/// repeating tiles use [GlassTile] (same language, no filter) to stay at
/// 60fps.
///
/// Light mode mirrors the recipe with translucent whites.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.selected = false,
    this.blur = 14,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool selected;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final fill = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.16)
        : isDark
            ? const Color(0xFF0D0F18).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.55);
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius =
        BorderRadius.circular((borderRadius - 1.5).clamp(0.0, 64.0));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        // 1. Directional edge-light rim.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.primary.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.08),
                  scheme.primary.withValues(alpha: 0.55),
                ]
              : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0.16),
                    ]
                  : [
                      Colors.white.withValues(alpha: 1),
                      Colors.white.withValues(alpha: 0.55),
                      scheme.onSurface.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.8),
                    ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          // 4. Holographic outer glow on selected surfaces.
          if (selected)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.45),
              blurRadius: 32,
            ),
        ],
      ),
      // The 1px rim: content is inset by the border thickness.
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: innerRadius,
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: fill),
                    ),
                  ),
                  // 3. Inner depth: lit top, shaded base.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x14FFFFFF),
                            Color(0x00FFFFFF),
                            Color(0x00FFFFFF),
                            Color(0x24000000),
                          ],
                          stops: [0.0, 0.28, 0.68, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // 2. Diagonal specular streak.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.1, -1.0),
                          end: Alignment(0.1, 1.0),
                          colors: [
                            Color(0x0FFFFFFF),
                            Color(0x05FFFFFF),
                            Color(0x00FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.0, 0.22, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                      onLongPress: onLongPress,
                      splashColor: Colors.white.withValues(alpha: 0.12),
                      highlightColor: Colors.white.withValues(alpha: 0.06),
                      customBorder:
                          RoundedRectangleBorder(borderRadius: innerRadius),
                      child: Padding(
                        padding: padding ?? EdgeInsets.zero,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Non-blurred glass tile for dense repeating surfaces (grid tiles, list
/// rows). Same fill/border language as [GlassCard] without the
/// [BackdropFilter] cost — dozens of these scroll at 60fps.
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 18,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final fill = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.16)
        : isDark
            ? const Color(0xFF0D0F18).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5);
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.primary.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.08),
                  scheme.primary.withValues(alpha: 0.55),
                ]
              : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.24),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.12),
                    ]
                  : [
                      Colors.white.withValues(alpha: 1),
                      Colors.white.withValues(alpha: 0.5),
                      scheme.onSurface.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.75),
                    ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.09),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (selected)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (borderRadius - 1).clamp(0.0, 64.0),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: fill),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.1, -1.0),
                      end: const Alignment(0.1, 1.0),
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
                        Colors.white.withValues(alpha: isDark ? 0.02 : 0.03),
                        const Color(0x00FFFFFF),
                        const Color(0x00FFFFFF),
                      ],
                      stops: const [0.0, 0.24, 0.44, 1.0],
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                  customBorder: RoundedRectangleBorder(borderRadius: radius),
                  child: Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blurred glass wrapper for chrome (bottom nav bars, overlay panels).
class GlassBlur extends StatelessWidget {
  const GlassBlur({
    super.key,
    required this.child,
    this.sigma = 22,
    this.tintAlpha,
  });

  final Widget child;
  final double sigma;
  final double? tintAlpha;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D1424).withValues(
                      alpha: tintAlpha ?? 0.6,
                    )
                  : Colors.white.withValues(alpha: tintAlpha ?? 0.65),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? _holoBlue.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Circular glass icon button (replaces the old neumorphic circle button).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassTile(
        borderRadius: 999,
        padding: EdgeInsets.zero,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

/// App-wide ambient backdrop: dark/light base with large soft accent blobs
/// for the frosted surfaces to refract. Mounted once in `AppShell` behind
/// every route (scaffolds are transparent). Pure gradients — no filters.
class GlassAmbientBackground extends StatelessWidget {
  const GlassAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070D) : const Color(0xFFF2F2F7),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -140,
            top: -120,
            child: _Blob(
              size: 340,
              color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.22),
            ),
          ),
          Positioned(
            right: -120,
            top: MediaQuery.sizeOf(context).height * 0.28,
            child: _Blob(
              size: 300,
              color: scheme.tertiary.withValues(alpha: isDark ? 0.18 : 0.18),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -140,
            child: _Blob(
              size: 320,
              color: scheme.secondary.withValues(alpha: isDark ? 0.15 : 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

/// Colored glowing icon chip for list/grid leadings — translucent [color]
/// rounded square, full-color glyph, soft outer glow. Gives monochrome rows
/// their color rhythm without layout changes.
class GlassIconChip extends StatelessWidget {
  const GlassIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize,
    this.radius,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius ?? size * 0.27),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
          stops: [0.0, 0.5],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: color),
    );
  }
}

/// Gradient glow call-to-action (primary → tertiary pill with outer glow)
/// for primary actions: new-window, backup/restore, permission grant.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Monochrome primary gradient — tertiary strays out of the theme
    // (yellowish on purple) so it is never used here.
    final deep = Color.lerp(scheme.primary, Colors.black, 0.28) ?? scheme.primary;
    final button = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(
          colors: [scheme.primary, deep],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    final tappable = Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: button,
      ),
    );
    if (!expanded) return tappable;
    return SizedBox(width: double.infinity, child: tappable);
  }
}
