import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' hide Column;
import 'package:share_plus/share_plus.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../blocs/auth_bloc.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _db = getIt<PosDatabase>();
  DateTime _from = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ); // Début du mois par défaut
  DateTime _to = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: 'Exporter le rapport',
          ),
        ],
      ),
      body: Column(
        children: [
          _dateRangeHeader(),
          Expanded(
            child: FutureBuilder<String?>(
              future: _db.getSetting('shop_id'),
              builder: (context, shopSnap) {
                if (!shopSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shopId = shopSnap.data!;

                return StreamBuilder<List<Expense>>(
                  stream: _db.watchExpenses(shopId, from: _from, to: _to),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? [];
                    final total = list.fold(0.0, (sum, e) => sum + e.amount);
                    final size = MediaQuery.of(context).size;

                    if (list.isEmpty) {
                      return const EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Aucune dépense sur cette période',
                        subtitle:
                            'Suivez vos frais fixes (loyer, factures) pour un calcul de profit net précis.',
                      );
                    }

                    final isDesktop = size.width > 1100;
                    final isTablet = size.width > 700 && size.width <= 1100;

                    return Column(
                      children: [
                        _buildModernHeader(total, isDesktop),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop
                                      ? 4
                                      : (isTablet ? 2 : 1),
                                  childAspectRatio: isDesktop ? 2.8 : 3.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: list.length,
                            itemBuilder: (context, index) => _ExpenseCard(
                              expense: list[index],
                              onDelete: () => _confirmDelete(list[index]),
                              onPrint: () => _printExpenseTicket(list[index]),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle dépense'),
      ),
    );
  }

  void _showForm() {
    showDialog(context: context, builder: (_) => const _ExpenseFormDialog());
  }

  Future<void> _printExpenseTicket(Expense expense) async {
    final user = context.read<AuthBloc>().state.user;
    final userName = user?.name ?? 'Utilisateur';

    final text = PrinterService.buildExpenseTicket(
      expense: expense,
      userName: userName,
    );

    // Données structurées pour le suivi (ID local, Montant, Timestamp)
    final qrData =
        'GPOS_EXP|ID:${expense.id}|AMT:${expense.amount}|TS:${expense.date.millisecondsSinceEpoch}';

    final success = await getIt<PrinterService>().printReport(
      text,
      qrData: qrData,
    );
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imprimante non connectée ou introuvable.'),
        ),
      );
    }
  }

  Widget _dateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(12), // Ligne 78
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _dateChip('Du', _from, () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _from,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _from = d);
            }),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→', style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: _dateChip('Au', _to, () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _to,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _to = d);
            }),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Ligne 114
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label : ${Fmt.date(date)}', // Ligne 123
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(double total, bool isDesktop) {
    return Container(
      margin: EdgeInsets.all(isDesktop ? 24 : 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ligne 143
            children: [
              const Text(
                'SOLDE DES DÉPENSES',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Fmt.currency(total),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          if (isDesktop)
            ElevatedButton.icon(
              onPressed: _showForm,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle écriture'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(Expense expense) async {
    final confirmed = await getIt<NavigationService>().showConfirm(
      title: 'Supprimer ?',
      content: 'Voulez-vous supprimer la dépense "${expense.description}" ?',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (confirmed) await _db.deleteExpense(expense.id);
  }

  Future<void> _exportReport() async {
    final shopId = await _db.getSetting('shop_id') ?? '';
    // Récupère les données filtrées actuelles
    final expenses = await _db
        .watchExpenses(shopId, from: _from, to: _to)
        .first;

    if (expenses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune dépense à exporter sur cette période.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Format d\'exportation'),
        content: const Text('Sélectionnez le format souhaité.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'CSV'),
            child: const Text('Excel (CSV)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'PREVIEW'),
            child: const Text('Aperçu PDF'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'PDF'),
            child: const Text('Partager PDF'),
          ),
        ],
      ),
    );

    if (format == null) return;

    if (format == 'PREVIEW') {
      await _previewReport(expenses);
    } else if (format == 'PDF') {
      await _exportPdf(expenses);
    } else {
      await _exportCsv(expenses);
    }
  }

  Future<void> _previewReport(List<Expense> list) async {
    final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';
    final total = list.fold(0.0, (sum, e) => sum + e.amount);

    final introText =
        'RAPPORT DE DÉPENSES\n'
        'Période : ${Fmt.date(_from)} au ${Fmt.date(_to)}\n'
        'Magasin : $shopName';

    final List<String> headers = [
      'Description',
      'Catégorie',
      'Date',
      'Montant',
    ];
    final List<List<String>> data = list
        .map(
          (e) => [
            e.description,
            e.category,
            Fmt.date(e.date),
            Fmt.currency(e.amount),
          ],
        )
        .toList();
    data.add(['', '', 'TOTAL', Fmt.currency(total)]);

    await getIt<PrinterService>().previewPdfReport(
      introText: introText,
      title: 'Rapport_Depenses',
      tableHeaders: headers,
      tableData: data,
    );
  }

  Future<void> _exportPdf(List<Expense> list) async {
    final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';
    final total = list.fold(0.0, (sum, e) => sum + e.amount);

    final introText =
        'RAPPORT DE DÉPENSES\n'
        'Période : ${Fmt.date(_from)} au ${Fmt.date(_to)}\n'
        'Magasin : $shopName';

    final List<String> headers = [
      'Description',
      'Catégorie',
      'Date',
      'Montant',
    ];
    final List<List<String>> data = list
        .map(
          (e) => [
            e.description,
            e.category,
            Fmt.date(e.date),
            Fmt.currency(e.amount),
          ],
        )
        .toList();
    data.add(['', '', 'TOTAL', Fmt.currency(total)]);

    await getIt<PrinterService>().sharePdfReport(
      fileName: 'Rapport_Depenses',
      introText: introText,
      shareMessage: 'Voici le rapport de dépenses de $shopName.',
      subject: 'Rapport de Dépenses',
      tableHeaders: headers,
      tableData: data,
    );
  }

  Future<void> _exportCsv(List<Expense> list) async {
    final rows = [
      ['Description', 'Catégorie', 'Date', 'Montant'],
      ...list.map(
        (e) => [
          e.description,
          e.category,
          Fmt.date(e.date),
          e.amount.toStringAsFixed(2),
        ],
      ),
    ];

    final csv = rows.map((r) => r.join(';')).join('\n');
    final directory = await getTemporaryDirectory();
    final path = p.join(
      directory.path,
      'depenses_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final file = File(path);
    await file.writeAsBytes([0xEF, 0xBB, 0xBF] + utf8.encode(csv));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'text/csv')],
        text: 'Export Dépenses',
        subject: 'Export Dépenses',
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback? onPrint;

  const _ExpenseCard({
    required this.expense,
    required this.onDelete,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: (expense.imagePath != null)
                  ? () => _showFullScreenImage(
                      context,
                      expense.imagePath!,
                      expense.description,
                    )
                  : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: expense.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(expense.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.category} • ${Fmt.date(expense.date)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '- ${Fmt.currency(expense.amount)}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onPrint,
                          icon: const Icon(
                            Icons.print_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche l'image du reçu en plein écran avec support du zoom (pinch-to-zoom).
void _showFullScreenImage(
  BuildContext context,
  String imagePath,
  String title,
) {
  showDialog(
    context: context,
    builder: (ctx) => Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(imagePath),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog();
  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Autre';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  final _categories = [
    'Loyer',
    'Électricité',
    'Salaire',
    'Transport',
    'Fournitures',
    'Marketing',
    'Autre',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
      );
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final String path = p.join(directory.path, 'expense_images');
      final Directory dir = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);

      final String fileName =
          'exp_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final String localPath = p.join(path, fileName);
      await File(image.path).copy(localPath);

      setState(() => _imagePath = localPath);
    } catch (e) {
      debugPrint('Erreur capture image : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer une dépense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zone de sélection d'image
            GestureDetector(
              onTap: () => _showImageSourceOptions(),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12), // Ligne 253
                  border: Border.all(color: AppColors.border),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Prendre en photo le reçu',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (ex: Facture Senelec)',
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'FCFA',
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Valider')),
      ],
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = getIt<PosDatabase>();
    final user = context.read<AuthBloc>().state.user!;
    final shopId = await db.getSetting('shop_id') ?? '';
    final terminalId = await db.getSetting('terminal_id') ?? '';

    await db.upsertExpense(
      ExpensesCompanion.insert(
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        category: _category,
        userId: user.id,
        shopId: Value(shopId),
        terminalId: Value(terminalId),
        imagePath: Value(_imagePath), // Enregistrement du chemin
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}
