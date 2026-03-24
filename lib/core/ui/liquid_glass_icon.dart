// lib/core/ui/liquid_glass_icon.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiquidGlassIcon extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final double size;
  final Color? accentColor;

  const LiquidGlassIcon({
    super.key,
    required this.icon,
    this.selected = false,
    this.size = 26,
    this.accentColor,
  });

  @override
  State<LiquidGlassIcon> createState() => _LiquidGlassIconState();
}

class _LiquidGlassIconState extends State<LiquidGlassIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.selected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(LiquidGlassIcon old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;

        // Ombre externe — deux BoxShadow fixes, jamais de liste vide
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  Colors.black.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.45),
                  t,
                )!,
                blurRadius: lerpDouble(10, 20, t)!,
                offset: Offset(0, lerpDouble(3, 6, t)!),
              ),
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: lerpDouble(0.10, 0.15, t)!),
                blurRadius: lerpDouble(4, 8, t)!,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              // Couche 1 : flou de fond variable
              filter: ImageFilter.blur(
                sigmaX: lerpDouble(14, 22, t)!,
                sigmaY: lerpDouble(14, 22, t)!,
              ),
              child: Stack(
                children: [
                  // Couche 2 : fond teinté
                  Container(
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.white.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.42),
                        t,
                      ),
                    ),
                  ),

                  // Couche 3 : reflet haut (spéculaire)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(
                                alpha: lerpDouble(0.55, 0.72, t)!),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Couche 4 : reflet bas (rebond)
                  Positioned(
                    bottom: 0, left: 8, right: 8,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.20),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Couche 5a : bord haut brillant (couleur UNIFORME → borderRadius OK)
                  // CORRECTION : on utilise un Container séparé par côté
                  // au lieu de Border(top:, left:, right:, bottom:) asymétrique
                  // Flutter interdit borderRadius avec couleurs de bords différentes

                  // Bord haut — le plus lumineux
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        // Couleur uniforme → pas d'erreur borderRadius
                        color: Colors.white.withValues(
                            alpha: lerpDouble(0.60, 0.78, t)!),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Bord gauche — luminosité moyenne
                  Positioned(
                    top: 1, left: 0, bottom: 0,
                    child: Container(
                      width: 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                            alpha: lerpDouble(0.28, 0.38, t)!),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Bord droit — le plus sombre
                  Positioned(
                    top: 1, right: 0, bottom: 0,
                    child: Container(
                      width: 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                            alpha: lerpDouble(0.08, 0.14, t)!),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Bord bas — rebond léger
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                            alpha: lerpDouble(0.12, 0.20, t)!),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Icône
                  Center(
                    child: Icon(
                      widget.icon,
                      size: widget.size,
                      color: Color.lerp(
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white,
                        t,
                      ),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(
                              alpha: lerpDouble(0.18, 0.32, t)!),
                          blurRadius: lerpDouble(3, 6, t)!,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}