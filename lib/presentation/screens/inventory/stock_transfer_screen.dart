import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/auth_bloc.dart';
import '../../../data/database/pos_database.dart';
import 'create_transfer_screen.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = getIt<PosDatabase>();
  String? _myShopId;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShopInfo();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShopInfo() async {
    final id = await _db.getSetting('shop_id');
    setState(() => _myShopId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher (Ref, Statut...)',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
              )
            : const Text('Transferts de Stock'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchCtrl.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: _myShopId == null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Center(child: LinearProgressIndicator()),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: StreamBuilder<List<StockTransfer>>(
                    stream: _db.watchIncomingTransfers(_myShopId!),
                    builder: (context, snapshot) {
                      final incomingCount = snapshot.data?.length ?? 0;
                      return TabBar(
                        controller: _tabController,
                        tabs: [
                          _buildTabWithBadge('À Recevoir', incomingCount),
                          const Tab(text: 'Historique / Envoi'),
                        ],
                      );
                    })),
      ),
      body: _myShopId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _IncomingTransfersList(shopId: _myShopId!, searchQuery: _searchQuery),
                _OutgoingTransfersList(shopId: _myShopId!, searchQuery: _searchQuery),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTransfer,
        label: const Text('Nouveau Transfert'),
        icon: const Icon(Icons.send_rounded),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _createNewTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTransferScreen()),
    ).then((_) => setState(() {})); // Rafraîchir au retour si nécessaire
  }

  Widget _buildTabWithBadge(String title, int count) {
    if (count == 0) {
      return Tab(text: title);
    }
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingTransfersList extends StatelessWidget {
  final String shopId;
  final String searchQuery;
  const _IncomingTransfersList({required this.shopId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return StreamBuilder<List<StockTransfer>>(
      stream: db.watchIncomingTransfers(shopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final list = snapshot.data!.where((t) {
          if (searchQuery.isEmpty) return true;
          return t.ref.toLowerCase().contains(searchQuery) ||
              t.status.toLowerCase().contains(searchQuery) ||
              (t.notes?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
        
        if (list.isEmpty) {
          return Center(child: Text(searchQuery.isEmpty ? "Aucun transfert en attente" : "Aucun résultat trouvé"));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final transfer = list[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.infoSoft,
                  child: Icon(Icons.download_rounded, color: AppColors.info),
                ),
                title: _ShopNameText(prefix: 'De:', shopId: transfer.sourceShopId),
                subtitle: Text('Ref: ${transfer.ref}\nStatut: ${transfer.status}'),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: () => _showReceiveDialog(context, transfer),
                  child: const Text('Réceptionner'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiveDialog(BuildContext context, StockTransfer transfer) {
    // Affiche le détail des produits et permet de valider les quantités reçues
    showDialog(
      context: context,
      builder: (_) => _TransferDetailsDialog(transfer: transfer),
    );
  }
}

class _OutgoingTransfersList extends StatelessWidget {
  final String shopId;
  final String searchQuery;
  const _OutgoingTransfersList({required this.shopId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return StreamBuilder<List<StockTransfer>>(
      stream: db.watchOutgoingTransfers(shopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final list = snapshot.data!.where((t) {
          if (searchQuery.isEmpty) return true;
          return t.ref.toLowerCase().contains(searchQuery) ||
              t.status.toLowerCase().contains(searchQuery) ||
              (t.notes?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();

        if (list.isEmpty) {
          return Center(child: Text(searchQuery.isEmpty ? "Aucun envoi effectué" : "Aucun résultat trouvé", style: const TextStyle(color: AppColors.textMuted)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final transfer = list[index];
            final statusColor = _getStatusColor(transfer.status);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.surface,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(Icons.upload_rounded, color: statusColor, size: 20),
                ),
                title: _ShopNameText(prefix: 'Vers:', shopId: transfer.targetShopId, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ref: ${transfer.ref}\nLe: ${Fmt.dateTime(transfer.createdAt)}'),
                isThreeLine: true,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _translateStatus(transfer.status),
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) => switch (status) {
        'pending' => AppColors.warning,
        'completed' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.textMuted,
      };

  String _translateStatus(String status) => switch (status) {
        'pending' => 'En attente',
        'completed' => 'Reçu',
        'rejected' => 'Rejeté',
        _ => status,
      };
}

class _TransferDetailsDialog extends StatefulWidget {
  final StockTransfer transfer;

  const _TransferDetailsDialog({required this.transfer});

  @override
  State<_TransferDetailsDialog> createState() => _TransferDetailsDialogState();
}

class _TransferDetailsDialogState extends State<_TransferDetailsDialog> {
  final _db = getIt<PosDatabase>();
  List<StockTransferItemWithProduct>? _items;
  final Map<int, int> _receivedQuantities = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _db.getStockTransferItemsWithProducts(widget.transfer.id);
      if (mounted) {
        setState(() {
          _items = items;
          // Initialiser avec les quantités envoyées par défaut
          for (var item in items) {
            _receivedQuantities[item.item.id] = item.item.quantitySent;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Réceptionner: ${widget.transfer.ref}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Text('Erreur: $_error', style: const TextStyle(color: AppColors.danger))
            : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Veuillez vérifier les produits et quantités reçus :', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items!.length,
                    itemBuilder: (context, index) {
                      final item = _items![index];
                      final qtySent = item.item.quantitySent;
                      final qtyReceived = _receivedQuantities[item.item.id] ?? qtySent;
                      
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
                        title: Text(item.product.name),
                        subtitle: Text('Envoyé: $qtySent'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () => _updateQty(item.item.id, -1),
                            ),
                            Text('$qtyReceived', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => _updateQty(item.item.id, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => _validateReception(context),
          child: const Text('Valider la Réception'),
        ),
      ],
    );
  }

  void _updateQty(int itemId, int delta) {
    final current = _receivedQuantities[itemId] ?? 0;
    final newVal = current + delta;
    if (newVal >= 0) {
      setState(() => _receivedQuantities[itemId] = newVal);
    }
  }

  Future<void> _validateReception(BuildContext context) async {
    final db = getIt<PosDatabase>();
    final userId = context.read<AuthBloc>().state.user?.id;

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur: Utilisateur non identifié.'),
              backgroundColor: AppColors.danger),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      await db.validateStockTransferReception(
        transferId: widget.transfer.id,
        userId: userId,
        actualQuantities: _receivedQuantities,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Ferme le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transfert validé et stock mis à jour.'),
            backgroundColor: AppColors.success),
      );

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Ferme le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}

/// Un petit widget pour récupérer et afficher le nom d'un magasin
/// à partir de son ID, avec un fallback sur l'ID si non trouvé.
class _ShopNameText extends StatelessWidget {
  final String shopId;
  final String prefix;
  final TextStyle? style;

  const _ShopNameText({required this.shopId, required this.prefix, this.style});

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return FutureBuilder<Shop?>(
      // Requête simple pour obtenir le magasin par son ID
      future: (db.select(db.shops)..where((s) => s.id.equals(shopId))).getSingleOrNull(),
      builder: (context, snapshot) {
        // Affiche l'ID si le nom n'est pas (encore) dans la base locale
        final shopName = snapshot.data?.name ?? shopId;
        return Text(
          '$prefix $shopName',
          style: style,
        );
      },
    );
  }
}