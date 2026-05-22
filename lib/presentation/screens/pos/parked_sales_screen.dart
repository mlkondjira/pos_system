import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart_bloc.dart';
import '../settings/glass_alert_dialog.dart';
import '../../widgets/shared_widgets.dart'; // Pour EmptyState si disponible

class ParkedSalesScreen extends StatelessWidget {
  const ParkedSalesScreen({super.key});

  void _confirmClearAll(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Tout supprimer'),
        content: const Text(
          'Voulez-vous vraiment supprimer toutes les ventes en attente ? Cette action est irréversible.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(ClearParkedSales());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Ventes en attente'),
        centerTitle: false,
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.parkedSales.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                onPressed: () => _confirmClearAll(context),
                tooltip: 'Tout supprimer',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.parkedSales.isEmpty) {
            return EmptyState(
              icon: Icons.pause_circle_outline,
              title: 'Aucune vente en attente',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour à la caisse'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.parkedSales.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final parked = state.parkedSales[index];
              final totalTtc = parked.items.fold(0.0, (s, i) => s + i.lineTotalTtc) - parked.globalDiscount;
              final itemCount = parked.items.fold(0, (s, i) => s + i.quantity);

              return _ParkedSaleTile(
                parked: parked,
                index: index,
                totalTtc: totalTtc,
                itemCount: itemCount,
              );
            },
          );
        },
      ),
    );
  }
}

class _ParkedSaleTile extends StatelessWidget {
  final CartParkedState parked;
  final int index;
  final double totalTtc;
  final int itemCount;

  const _ParkedSaleTile({
    required this.parked,
    required this.index,
    required this.totalTtc,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_basket_outlined, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                parked.label.isNotEmpty ? parked.label : 'Vente sans nom',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Text(
              Fmt.currency(totalTtc),
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Mise en attente à ${parked.parkedAt.hour}:${parked.parkedAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.layers_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '$itemCount article(s)',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () {
            context.read<CartBloc>().add(DeleteParkedCart(index));
          },
        ),
        onTap: () {
          // On restaure la vente
          context.read<CartBloc>().add(RestoreParkedCart(index));
          // On ferme l'écran pour revenir à la caisse
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vente "${parked.label}" restaurée')),
          );
        },
      ),
    );
  }
}