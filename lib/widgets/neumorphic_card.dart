import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access theme
    final theme = Provider.of<ThemeService>(context).currentTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.name == 'Glass' ? theme.surfaceColor : theme.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: theme.glassBorderColor != null
            ? Border.all(color: theme.glassBorderColor!)
            : null,
        boxShadow:
            theme.name == 'Neumorphism' ||
                theme.name == 'Cream' ||
                theme.name == 'Dark'
            ? [
                // Light shadow (top-left)
                BoxShadow(
                  color: theme.lightShadow,
                  offset: const Offset(-5, -5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                // Dark shadow (bottom-right)
                BoxShadow(
                  color: theme.darkShadow,
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [], // No shadow for flat glass usually, or adds specific glass shadow if needed
      ),
      child: child,
    );
  }
}
