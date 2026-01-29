import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

// Helper for Glassmorphic background
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context).currentTheme;

    // If not Glass theme, return solid background
    if (theme.name != 'Glass') {
      return Container(
        color: theme.baseColor,
        child: SafeArea(child: child),
      );
    }

    return Stack(
      children: [
        // Base color
        Container(color: theme.baseColor),

        // Dynamic circles/gradients for "Glass" effect to show through
        Positioned(
          top: -50,
          left: -50,
          child: _buildCircle(200, theme.accentColor.withOpacity(0.2)),
        ),
        Positioned(
          bottom: 100,
          right: -30,
          child: _buildCircle(150, theme.secondaryAccentColor.withOpacity(0.2)),
        ),
        Positioned(
          top: 150,
          right: 50,
          child: _buildCircle(80, Colors.orange.withOpacity(0.15)),
        ),

        // Backdrop Blur (Glass)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: theme.baseColor == const Color(0xFF0F172A)
                  ? Colors
                        .transparent // For our Glass theme, base is already dark, we rely on surface colors for cards mostly OR we can add a slight tint
                  : Colors.white.withOpacity(0.1),
            ),
          ),
        ),

        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
