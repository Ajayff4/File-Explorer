import 'package:flutter/material.dart';

/// Neumorphic card: soft extruded-plastic surface matching the background hue.
///
/// Recipe (CRED-style soft UI / neumorphism):
/// - surface color equals the surrounding background (monochrome, no tint)
/// - dual shadow: light source top-left, dark bottom-right
/// - no gradients, no hue-keyed colors — soft depth is all shadow
/// - large radius + tactile press feedback (inset swap) on tap
class NeumorphicCard extends StatefulWidget {
  const NeumorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.color,
    this.inset = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool inset;

  @override
  State<NeumorphicCard> createState() => _NeumorphicCardState();
}

class _NeumorphicCardState extends State<NeumorphicCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final base = widget.color ?? theme.scaffoldBackgroundColor;
    final pressable = widget.onTap != null;

    // Neumorphic light/dark shadow pairs, derived from the base surface hue.
    final lightShadow = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.06),
            base,
          )
        : Color.alphaBlend(
            Colors.white.withValues(alpha: 0.8),
            base,
          );
    final darkShadow = isDark
        ? Color.alphaBlend(
            Colors.black.withValues(alpha: 0.6),
            base,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.18),
            base,
          );

    final radius = BorderRadius.circular(widget.borderRadius);

    // Raised: light top-left, dark bottom-right. Pressed/inset: inverted.
    final pressed = _pressed || widget.inset;
    final shadows = pressed
        ? <BoxShadow>[
            BoxShadow(
              color: darkShadow,
              blurRadius: widget.borderRadius * 0.5,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: lightShadow,
              blurRadius: widget.borderRadius * 0.5,
              offset: const Offset(-4, -4),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: darkShadow,
              blurRadius: widget.borderRadius * 0.5,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: lightShadow,
              blurRadius: widget.borderRadius * 0.5,
              offset: const Offset(-4, -4),
            ),
            BoxShadow(
              color: lightShadow,
              blurRadius: widget.borderRadius,
              offset: const Offset(-6, -6),
            ),
          ];

    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: pressable
              ? () {
                  setState(() => _pressed = true);
                  Future<void>.delayed(const Duration(milliseconds: 110), () {
                    if (mounted) {
                      setState(() => _pressed = false);
                    }
                    widget.onTap?.call();
                  });
                }
              : null,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
        ),
      ),
    );

    return card;
  }
}
