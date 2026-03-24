// lib/presentation/widgets/shared_widgets.dart
// Widgets réutilisables dans tout le projet
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Écran vide avec icône et message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 13,
            ), textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ]),
      ),
    );
  }
}

/// Badge coloré (statut, stock, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }
}

/// Titre de section
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ));
  }
}

/// Stepper quantité +/-
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _btn(Icons.remove, () { if (value > min) onChanged(value - 1); }, value <= min),
      SizedBox(
        width: 36,
        child: Text('$value', textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      _btn(Icons.add, () { if (value < max) onChanged(value + 1); }, value >= max),
    ]);
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool disabled) =>
      GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surfaceLight
                : AppColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14,
              color: disabled ? AppColors.textMuted : AppColors.primaryLight),
        ),
      );
}

/// Clavier numérique
class NumPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  const NumPad({super.key, required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','.','0'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.4,
      children: [
        ...keys.map((k) => _Key(label: k, onTap: () => onKey(k))),
        _Key(icon: Icons.backspace_outlined, onTap: onBackspace,
            color: AppColors.textMuted),
      ],
    );
  }
}

class PosSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const PosSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
        isDense: true,
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  const _Key({this.label, this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(label!, style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w500))
            : Icon(icon, color: color ?? AppColors.textPrimary, size: 18),
      ),
    );
  }
}
