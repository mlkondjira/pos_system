import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showBlobs;

  const AppBackground({
    super.key,
    required this.child,
    this.showBlobs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Fond de base avec le dégradé dynamique
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.gradientMain(context)),
        ),

        // 2. Blobs colorés optionnels (style Login)
        if (showBlobs) ...[
          Positioned(
            top: -100,
            right: -50,
            child: _buildBackgroundBlob(300, AppColors.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _buildBackgroundBlob(250, AppColors.accent.withValues(alpha: 0.12)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: -100,
            child: _buildBackgroundBlob(200, AppColors.primary.withValues(alpha: 0.1)),
          ),
        ],

        // 3. Contenu principal
        child,
      ],
    );
  }

  Widget _buildBackgroundBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent)),
      ),
    );
  }
}