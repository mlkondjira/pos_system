// lib/data/services/printer_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../database/pos_database.dart';

class PrinterService {
  final PosDatabase _db;
  BluetoothConnection? _connection;
  String? _connectedMac;

  // Le service a besoin de la DB pour lire les paramètres (nom imprimante, etc)
  PrinterService(this._db);

  bool get isConnected => _connection?.isConnected ?? false;
  String? get connectedMac => _connectedMac;

  /// Lister les appareils Bluetooth couplés
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Connecter à une imprimante
  Future<bool> connect(String mac) async {
    try {
      if (_connection != null) await disconnect();
      _connection = await BluetoothConnection.toAddress(mac);
      _connectedMac = mac;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _connectedMac = null;
  }

  /// Imprime un reçu en choisissant la méthode (Bluetooth/ESC-POS ou USB/PDF) selon la plateforme.
  Future<bool> printReceipt({
    required String ref,
    required DateTime date,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double totalHt,
    required double totalTax,
    required double totalTtc,
    required double discountAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeGiven,
    String? customerName,
    String? currency,
    int paperWidthChars = 42,
  }) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Mon Magasin';
    final shopAddress = settings['shop_address'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final footer = settings['receipt_footer'] ?? 'Merci !';
    final logoPath = settings['shop_logo_path'];

    // Charger l'image du logo si elle existe
    img.Image? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        logoImage = img.decodeImage(await file.readAsBytes());
      }
    }

    // --- Logique pour Windows (USB/Réseau via PDF) ---
    if (Platform.isWindows) {
      try {
        final printerName = await _db.getSetting('printer_name');
        if (printerName == null || printerName.isEmpty) return false;

        final printers = await Printing.listPrinters();
        final selectedPrinter = printers.firstWhere((p) => p.name == printerName);

        final pdfBytes = await _generatePdfReceipt(
            ref: ref,
            date: date,
            cashierName: cashierName,
            items: items,
            totalHt: totalHt,
            totalTax: totalTax,
            totalTtc: totalTtc,
            discountAmount: discountAmount,
            paymentMethod: paymentMethod,
            amountPaid: amountPaid,
            changeGiven: changeGiven,
            customerName: customerName,
            currency: currency,
            shopName: shopName,
            shopAddress: shopAddress,
            shopPhone: shopPhone,
            footer: footer,
            logoPath: logoPath);

        return await Printing.directPrintPdf(printer: selectedPrinter, onLayout: (_) => pdfBytes);
      } catch (e) {
        debugPrint("Erreur d'impression Windows: $e");
        return false;
      }
    }

    // --- Logique pour Android (Bluetooth/ESC-POS) ---
    if (Platform.isAndroid) {
      if (!isConnected) return false;
      try {
        final text = buildReceiptText(
            ref: ref, date: date, cashierName: cashierName, items: items, totalHt: totalHt, totalTax: totalTax, totalTtc: totalTtc, discountAmount: discountAmount, paymentMethod: paymentMethod, amountPaid: amountPaid, changeGiven: changeGiven, customerName: customerName, currency: currency, width: paperWidthChars);

        final bytes = _buildEscPos(
          text: text,
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          footer: footer,
          logo: logoImage,
          width: paperWidthChars,
        );
        _connection!.output.add(Uint8List.fromList(bytes));
        await _connection!.output.allSent;
        return true;
      } catch (e) {
        return false;
      }
    }

    return false; // Plateforme non supportée
  }

  /// Imprime un rapport textuel (ex: Clôture de caisse)
  Future<bool> printReport(String text) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Mon Magasin';
    final shopAddress = settings['shop_address'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final footer = settings['receipt_footer'] ?? '';
    final logoPath = await _db.getSetting('shop_logo_path');

    // Charger l'image du logo si elle existe
    img.Image? logoImage;
    pw.Widget? logoPdfWidget;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        logoImage = img.decodeImage(bytes);
        // Windows: Augmenter 'height' ici pour agrandir le logo (ex: 80 au lieu de 48)
        logoPdfWidget = pw.Image(pw.MemoryImage(bytes), height: 80);
      }
    }

    if (Platform.isWindows) {
      try {
        final printerName = await _db.getSetting('printer_name');
        if (printerName == null || printerName.isEmpty) return false;

        final printers = await Printing.listPrinters();
        final selectedPrinter = printers.firstWhere((p) => p.name == printerName);

        final doc = pw.Document();
        final pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);

        doc.addPage(pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoPdfWidget != null) pw.Center(child: logoPdfWidget),
              if (logoPdfWidget != null) pw.SizedBox(height: 5),
              pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.SizedBox(height: 10),
              pw.Text(text, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9)),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text(footer, style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
        ));

        return await Printing.directPrintPdf(printer: selectedPrinter, onLayout: (_) => doc.save());
      } catch (e) {
        debugPrint("Erreur impression rapport Windows: $e");
        return false;
      }
    }

    if (Platform.isAndroid && isConnected) {
      final bytes = _buildEscPos(
          text: text,
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          footer: footer,
          width: 42,
          logo: logoImage);
      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;
      return true;
    }
    return false;
  }

  List<int> _buildEscPos({
    required String text,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String footer,
    img.Image? logo,
    required int width,
  }) {
    // Commandes ESC/POS de base
    const esc = 0x1B;
    const gs = 0x1D;
    const lf = 0x0A;

    final List<int> bytes = [];

    void add(List<int> data) => bytes.addAll(data);
    void addText(String s) => bytes.addAll(s.codeUnits);
    void newLine([int n = 1]) => bytes.addAll(List.filled(n, lf));
    void separator() => addText('-' * width);

    // Init
    add([esc, 0x40]); // Reset

    // Imprimer le logo si disponible
    if (logo != null) {
      add([esc, 0x61, 0x01]); // Centrer
      add(_generateEscPosImage(logo, width: width));
    }

    add([esc, 0x61, 0x01]); // Centrer

    // En-tête gras
    add([esc, 0x45, 0x01]); // Bold ON
    add([gs, 0x21, 0x11]); // Double taille
    addText(shopName.toUpperCase());
    newLine();
    add([gs, 0x21, 0x00]); // Taille normale
    add([esc, 0x45, 0x00]); // Bold OFF

    if (shopAddress.isNotEmpty) { addText(shopAddress); newLine(); }
    if (shopPhone.isNotEmpty) { addText('Tél: $shopPhone'); newLine(); }
    newLine();

    // Corps du reçu (aligné gauche)
    add([esc, 0x61, 0x00]);
    separator(); newLine();
    addText(text);
    separator(); newLine();

    // Pied de page centré
    add([esc, 0x61, 0x01]);
    newLine();
    addText(footer);
    newLine(3);

    // Cut
    add([gs, 0x56, 0x41, 0x03]);

    return bytes;
  }

  /// Convertit une image en données raster ESC/POS (GS v 0)
  /// Gère le redimensionnement et la conversion en monochrome.
  List<int> _generateEscPosImage(img.Image image, {int width = 42}) {
    final List<int> bytes = [];

    // Largeur max en pixels pour papier 80mm (~48 chars) et 58mm (~32 chars)
    final int maxWidth = (width > 40) ? 576 : 384;

    // Android/Bluetooth : On limite la largeur du logo à 60% du papier
    // pour éviter qu'il soit trop gros. Ajustez 0.6 selon vos goûts.
    final int logoTargetWidth = (maxWidth * 0.6).toInt();

    // Redimensionner, convertir en niveaux de gris
    final resized = img.copyResize(image, width: logoTargetWidth);
    final mono = img.grayscale(resized);
    final imgWidth = mono.width;
    final imgHeight = mono.height;

    // Commande pour définir l'espacement des lignes à 24 points (meilleur pour les images)
    bytes.addAll([0x1B, 0x33, 24]);

    int offset = 0;
    while (offset < imgHeight) {
      // Commande pour imprimer une image raster: GS v 0 m xL xH yL yH d...
      // m=0 (mode normal)
      bytes.addAll([0x1D, 0x76, 0x30, 0x00]);

      // Calculer la hauteur de la tranche (max 255 pour la commande)
      final sliceHeight = (imgHeight - offset) > 255 ? 255 : (imgHeight - offset);

      // Définir la largeur et la hauteur de la tranche
      bytes.addAll([imgWidth % 256, imgWidth ~/ 256]);
      bytes.addAll([sliceHeight % 256, sliceHeight ~/ 256]);

      // Générer les données de la tranche en format colonne
      for (int x = 0; x < imgWidth; x++) {
        for (int y = 0; y < sliceHeight; y += 8) {
          int byte = 0;
          for (int bit = 0; bit < 8; bit++) {
            if ((y + bit) < sliceHeight) {
              if (mono.getPixel(x, offset + y + bit).luminance < 128) { // Pixel noir
                byte |= (1 << (7 - bit));
              }
            }
          }
          bytes.add(byte);
        }
      }
      offset += sliceHeight;
    }

    // Réinitialiser l'espacement des lignes par défaut
    bytes.addAll([0x1B, 0x32]);
    return bytes;
  }

  /// Génère un reçu au format PDF pour l'impression sur Windows.
  Future<Uint8List> _generatePdfReceipt({
    required String ref,
    required DateTime date,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double totalHt,
    required double totalTax,
    required double totalTtc,
    required double discountAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeGiven,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String footer,
    String? logoPath,
    String? customerName,
    String? currency,
  }) async {
    final doc = pw.Document();
    // Format 80mm, hauteur infinie, marges de 3mm
    final pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm);

    // Charger le logo si le chemin est fourni
    pw.Widget? logoWidget;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        logoWidget = pw.Image(
          pw.MemoryImage(await file.readAsBytes()),
          height: 80, // Windows: Ajustez la taille ici aussi pour les tickets de vente
        );
      }
    }

    // Note: pour une police monospace, il faudrait l'ajouter aux assets et la charger ici.
    // final font = pw.Font.ttf(await rootBundle.load("assets/fonts/RobotoMono-Regular.ttf"));

    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        // Le texte brut est généré par la méthode existante, on le réutilise pour le PDF.
        final receiptText = buildReceiptText(
          ref: ref, date: date, cashierName: cashierName, items: items, totalHt: totalHt, totalTax: totalTax, totalTtc: totalTtc, discountAmount: discountAmount, paymentMethod: paymentMethod, amountPaid: amountPaid, changeGiven: changeGiven, customerName: customerName, currency: currency, width: 48, // Largeur de caractères pour PDF
        );

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            if (logoWidget != null) pw.Center(child: logoWidget),
            if (logoWidget != null) pw.SizedBox(height: 5),
            pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
            if (shopAddress.isNotEmpty) pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9))),
            if (shopPhone.isNotEmpty) pw.Center(child: pw.Text('Tél: $shopPhone', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 8),
            pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 5),

            // Corps du reçu
            pw.Text(
              receiptText,
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8, lineSpacing: 2),
            ),

            // Pied de page
            pw.SizedBox(height: 5),
            pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text(footer, style: const pw.TextStyle(fontSize: 9))),
          ],
        );
      },
    ));

    return doc.save();
  }

  /// Générer le texte du rapport de clôture de caisse
  static String buildCashSessionReport({
    required CashSession session,
    required String userName,
    required List<Payment> payments,
    String currency = 'F',
    int width = 42,
  }) {
    final buf = StringBuffer();
    String pad(String s, int len) => s.padRight(len);
    String padLeft(String s, int len) => s.padLeft(len);

    String fmt(double v) {
      final n = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]} ');
      return '$n $currency';
    }

    buf.writeln('RAPPORT DE CLOTURE DE CAISSE');
    buf.writeln();
    buf.writeln('Session du: ${session.startedAt.day}/${session.startedAt.month}/${session.startedAt.year}');
    buf.writeln('De: ${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')} à ${session.endedAt?.hour.toString().padLeft(2, '0')}:${session.endedAt?.minute.toString().padLeft(2, '0')}');
    buf.writeln('Utilisateur: $userName');
    buf.writeln('-' * width);

    buf.writeln(padLeft('ATTENDU', width));
    buf.writeln(pad('Fond de caisse', 30) + padLeft(fmt(session.startingCash), width - 30));

    final cashSales = payments.where((p) => p.method == 'cash').fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);
    buf.writeln(pad('Ventes (espèces)', 30) + padLeft(fmt(cashSales), width - 30));
    buf.writeln(padLeft('-' * 12, width));
    buf.writeln(pad('TOTAL ATTENDU', 30) + padLeft(fmt(session.expectedCash ?? 0), width - 30));
    buf.writeln();

    buf.writeln(padLeft('COMPTE', width));
    buf.writeln(pad('Total compté', 30) + padLeft(fmt(session.endingCash ?? 0), width - 30));
    buf.writeln(pad('ECART', 30) + padLeft(fmt(session.discrepancy ?? 0), width - 30));
    buf.writeln();

    buf.writeln(padLeft('AUTRES PAIEMENTS', width));
    final otherPayments = payments.where((p) => p.method != 'cash').fold<Map<String, double>>({}, (map, p) {
      map[p.method] = (map[p.method] ?? 0) + p.amount - p.changeGiven;
      return map;
    });

    for (final entry in otherPayments.entries) {
      buf.writeln(pad(_fmtMethod(entry.key), 30) + padLeft(fmt(entry.value), width - 30));
    }
    buf.writeln();

    return buf.toString();
  }

  /// Générer le texte du reçu à partir des données de vente
  static String buildReceiptText({
    required String ref,
    required DateTime date,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double totalHt,
    required double totalTax,
    required double totalTtc,
    required double discountAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeGiven,
    String? customerName,
    String? currency,
    int width = 42,
  }) {
    final sym = currency ?? 'F';
    final buf = StringBuffer();

    String pad(String s, int len, {bool right = false}) {
      if (s.length >= len) return s.substring(0, len);
      return right ? s.padLeft(len) : s.padRight(len);
    }

    String fmt(double v) {
      final n = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]} ');
      return '$n $sym';
    }

    buf.writeln('Date: ${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}  ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}');
    buf.writeln('N° $ref');
    buf.writeln('Caissier: $cashierName');
    if (customerName != null) buf.writeln('Client: $customerName');
    buf.writeln();

    // En-têtes colonnes
    buf.writeln('${pad("Article", 22)}${pad("Qté", 5, right: true)}${pad("Total", width - 27, right: true)}');
    buf.writeln('-' * width);

    for (final item in items) {
      final name = item['name'] as String;
      final qty = item['qty'] as int;
      final total = item['total'] as double;
      final price = item['price'] as double;

      buf.writeln(pad(name.length > 22 ? name.substring(0, 22) : name, 22));
      buf.writeln('  ${pad(price.toStringAsFixed(0), 18)}${pad(qty.toString(), 5, right: true)}${pad(fmt(total), width - 23, right: true)}');
    }

    buf.writeln('-' * width);

    if (totalHt != totalTtc) {
      buf.writeln('${pad("Sous-total HT", 30)}${pad(fmt(totalHt), width - 30, right: true)}');
      buf.writeln('${pad("TVA", 30)}${pad(fmt(totalTax), width - 30, right: true)}');
    }
    if (discountAmount > 0) {
      buf.writeln('${pad("Remise", 30)}${pad("-${fmt(discountAmount)}", width - 30, right: true)}');
    }
    buf.writeln('-' * width);
    buf.writeln('${pad("TOTAL TTC", 30)}${pad(fmt(totalTtc), width - 30, right: true)}');
    buf.writeln();
    buf.writeln('${pad("Paiement (${_fmtMethod(paymentMethod)})", 30)}${pad(fmt(amountPaid), width - 30, right: true)}');
    if (changeGiven > 0) {
      buf.writeln('${pad("Rendu monnaie", 30)}${pad(fmt(changeGiven), width - 30, right: true)}');
    }
    buf.writeln();

    return buf.toString();
  }

  static String _fmtMethod(String m) {
    switch (m) {
      case 'cash': return 'Espèces';
      case 'card': return 'Carte';
      case 'mobile_money': return 'Mobile Money';
      default: return m;
    }
  }
}
