// lib/data/services/printer_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Keep for debugPrint
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; // Nouveau package
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' hide PdfImage;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_pos_printer_platform_image_3_sdt/flutter_pos_printer_platform_image_3_sdt.dart'
    as pos_printer;
import '../database/pos_database.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';
import '../../core/utils/formatters.dart';
import 'dart:convert' show latin1;

enum AppPrinterType {
  none,
  bluetooth,
  usb,
  network,
  systemPdf, // For Windows direct PDF printing
}

class PrinterService {
  final PosDatabase _db;
  final BlueThermalPrinter _bluetooth =
      BlueThermalPrinter.instance; // Instance du nouveau package
  final pos_printer.PrinterManager _printerManager =
      pos_printer.PrinterManager.instance; // NEW
  BluetoothDevice? _connectedDevice; // Pour suivre l'appareil connecté
  pos_printer.PrinterDevice? _connectedUsbPrinter; // NEW
  AppPrinterType _currentPrinterType =
      AppPrinterType.none; // NEW: Store the active printer type

  // Le service a besoin de la DB pour lire les paramètres (nom imprimante, etc)
  PrinterService(this._db);

  String? get connectedMac => _connectedDevice?.address;

  /// Lister les appareils Bluetooth couplés
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  /// Connecter à une imprimante Bluetooth
  Future<bool> connect(String mac) async {
    try {
      if (_connectedDevice != null) {
        await disconnect();
      }

      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      final BluetoothDevice? targetDevice = devices.firstWhereOrNull(
        (device) => device.address == mac,
      );

      if (targetDevice == null) {
        debugPrint(
          'Imprimante Bluetooth non trouvée parmi les appareils couplés: $mac',
        );
        return false;
      }

      await _bluetooth.connect(targetDevice);
      // Attendre un peu plus pour la stabilité sur Android
      await Future.delayed(const Duration(seconds: 1));
      if (await _bluetooth.isConnected == true) {
        _connectedDevice = targetDevice;
        _currentPrinterType = AppPrinterType.bluetooth; // NEW
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Erreur de connexion à l'imprimante Bluetooth: $e");
      return false;
    }
  }

  // --- USB specific methods (NEW) ---
  Future<List<pos_printer.PrinterDevice>> getUsbPrinters() async {
    // Convertit le Stream de découverte en une liste pour correspondre au Future attendu
    return await _printerManager
        .discovery(type: pos_printer.PrinterType.usb)
        .toList();
  }

  Future<bool> connectUsb(pos_printer.PrinterDevice printer) async {
    try {
      if (_connectedDevice != null || _connectedUsbPrinter != null) {
        await disconnect();
      }

      final bool isConnected = await _printerManager.connect(
        type: pos_printer.PrinterType.usb,
        model: pos_printer.UsbPrinterInput(
          name: printer.name,
          productId: printer.productId?.toString() ?? '',
          vendorId: printer.vendorId?.toString() ?? '',
        ),
      );

      if (isConnected) {
        _connectedUsbPrinter = printer;
        _currentPrinterType = AppPrinterType.usb;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Erreur de connexion à l'imprimante USB: $e");
      return false;
    }
  }

  bool get isConnected {
    if (_currentPrinterType == AppPrinterType.bluetooth) {
      return _connectedDevice != null;
    } else if (_currentPrinterType == AppPrinterType.usb) {
      return _connectedUsbPrinter != null;
    }
    return false;
  }

  Future<void> disconnect() async {
    if (_currentPrinterType == AppPrinterType.bluetooth) {
      await _bluetooth.disconnect();
      _connectedDevice = null;
    } else if (_currentPrinterType == AppPrinterType.usb) {
      await _printerManager.disconnect(type: pos_printer.PrinterType.usb);
      _connectedUsbPrinter = null;
    }
    _currentPrinterType = AppPrinterType.none;
  }

  /// Vérifie si le module Bluetooth du smartphone est activé.
  Future<bool> isBluetoothOn() async {
    return await _bluetooth.isOn ?? false;
  }

  /// Vérifie si l'imprimante est prête à l'emploi.
  /// Tente de se reconnecter automatiquement si une adresse MAC est enregistrée.
  Future<bool> isReady() async {
    final printerTypeStr = await _db.getSetting('printer_type'); // NEW
    _currentPrinterType = AppPrinterType.values.firstWhere(
      // NEW
      (e) => e.toString() == 'AppPrinterType.$printerTypeStr',
      orElse: () => AppPrinterType.none,
    );

    if (_currentPrinterType == AppPrinterType.bluetooth) {
      // NEW
      final mac = await _db.getSetting('printer_mac');
      if (mac == null || mac.isEmpty) {
        return false;
      }
      final bool? connected = await _bluetooth.isConnected;
      if (connected == true) {
        return true;
      }
      return await connect(mac);
    } else if (_currentPrinterType == AppPrinterType.usb) {
      // NEW
      final vendorId = await _db.getSetting('printer_usb_vendor_id');
      final productId = await _db.getSetting('printer_usb_product_id');
      if (vendorId == null ||
          productId == null ||
          vendorId.isEmpty ||
          productId.isEmpty) {
        return false;
      }

      // On vérifie si l'imprimante est toujours physiquement présente sur le bus USB
      final List<pos_printer.PrinterDevice> usbPrinters =
          await getUsbPrinters();
      final pos_printer.PrinterDevice? targetPrinter = usbPrinters
          .firstWhereOrNull(
            (p) =>
                p.vendorId?.toString() == vendorId &&
                p.productId?.toString() == productId,
          );

      if (targetPrinter == null) {
        // L'imprimante a été débranchée physiquement
        _connectedUsbPrinter = null;
        return false;
      }

      // Si elle est présente et qu'on est déjà connecté logiciellement, c'est bon
      if (_connectedUsbPrinter != null) {
        return true;
      }

      // Sinon, on tente une reconnexion automatique
      return await connectUsb(targetPrinter);
    } else if (_currentPrinterType == AppPrinterType.systemPdf) {
      // NEW
      final printerName = await _db.getSetting('printer_name');
      return printerName != null && printerName.isNotEmpty;
    }
    return false;
  }

  /// Imprime un ticket de test pour vérifier la connexion
  Future<bool> printTestReceipt() async {
    final now = DateTime.now();
    final items = [
      {'name': 'TEST IMPRESSION', 'qty': 1, 'price': 0.0, 'total': 0.0},
    ];

    return await printReceipt(
      ref: 'TEST-0001',
      date: now,
      cashierName: 'Système',
      items: items,
      totalHt: 0.0,
      totalTax: 0.0,
      totalTtc: 0.0,
      discountAmount: 0.0,
      paymentMethod: 'TEST',
      amountPaid: 0.0,
      changeGiven: 0.0,
    );
  }

  /// Imprime un reçu complet à partir d'une vente et de ses articles (réimpression).
  Future<bool> printSale({
    required Sale sale,
    required List<SaleItem> items,
    String? cashierName,
    String? customerName,
    String paymentMethod = 'cash',
    double amountPaid = 0,
    double changeGiven = 0,
  }) async {
    final printItems = items
        .map(
          (i) => {
            'name': i.productName,
            'barcode': i.barcode ?? '',
            'qty': i.quantity,
            // On utilise le prix TTC pour le client
            'price': i.unitPriceHt * (1 + i.taxRate),
            'total': i.lineTotal,
          },
        )
        .toList();

    return await printReceipt(
      ref: sale.ref,
      date: sale.createdAt,
      cashierName: cashierName ?? 'Caissier',
      items: printItems,
      totalHt: sale.totalHt,
      totalTax: sale.totalTax,
      totalTtc: sale.totalTtc,
      discountAmount: sale.discountAmount,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      customerName: customerName,
      qrData: sale.fiscalHash,
    );
  }

  /// Génère un PDF du ticket et ouvre le menu de partage (WhatsApp, Email, etc.)
  Future<void> shareSaleAsPdf({
    required Sale sale,
    required List<SaleItem> items,
    String? cashierName,
    String? customerName,
    String paymentMethod = 'cash',
    double amountPaid = 0,
    double changeGiven = 0,
  }) async {
    final printItems = items
        .map(
          (i) => {
            'name': i.productName,
            'qty': i.quantity,
            'price': i.unitPriceHt * (1 + i.taxRate),
            'total': i.lineTotal,
          },
        )
        .toList();

    final text = buildReceiptText(
      ref: sale.ref,
      date: sale.createdAt,
      cashierName: cashierName ?? 'Caissier',
      items: printItems,
      totalHt: sale.totalHt,
      totalTax: sale.totalTax,
      totalTtc: sale.totalTtc,
      discountAmount: sale.discountAmount,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      customerName: customerName,
      width: 42,
    );

    await sharePdfReport(
      fileName: 'Ticket_${sale.ref}',
      introText: text,
      shareMessage:
          'Voici votre ticket de caisse pour la commande ${sale.ref}. Merci de votre confiance !',
      subject: 'Ticket de caisse - ${sale.ref}',
      // On peut ajouter un tableau structuré pour le PDF A4
      tableHeaders: ['Article', 'Qté', 'Prix Unitaire', 'Total'],
      tableData: printItems
          .map(
            (i) => [
              i['name'] as String,
              i['qty'].toString(),
              Fmt.currency(i['price'] as double),
              Fmt.currency(i['total'] as double),
            ],
          )
          .toList(),
      qrData: sale.fiscalHash,
    );
  }

  /// Génère un rapport PDF consolidé pour plusieurs bons de commande (Rapport matinal).
  Future<void> shareBulkPurchaseOrdersPdf({
    required String fileName,
    required List<PurchaseOrderWithSupplier> orders,
    required PosDatabase db,
    required String shopName,
  }) async {
    final doc = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');

    for (final order in orders) {
      final items = await db.getPurchaseOrderItemsWithProducts(
        order.purchaseOrder.id,
      );
      final introText = PrinterService.buildPurchaseOrderReport(
        po: order.purchaseOrder,
        supplier: order.supplier,
        items: items,
        shopName: shopName,
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: pw.Font.ttf(fontData),
            bold: pw.Font.ttf(fontBoldData),
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                introText,
                style: pw.TextStyle(
                  font: pw.Font.courier(),
                  fontSize: 10,
                  lineSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    final bytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, '$fileName.pdf');
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(filePath, name: '$fileName.pdf', mimeType: 'application/pdf'),
        ],
        subject: 'Bons de Commande du Matin',
        text:
            'Veuillez trouver ci-joint les bons de commande générés ce matin.',
      ),
    );
  }

  /// Envoie un reçu textuel structuré directement sur WhatsApp
  Future<void> shareSaleViaWhatsApp({
    required Sale sale,
    required List<SaleItem> items,
    required String phone,
    String? customerName,
  }) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Mon Magasin';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final itemsText = items
        .map(
          (i) =>
              '• ${i.quantity}x ${i.productName} (${Fmt.currency(i.lineTotal)})',
        )
        .join('\n');

    final message =
        "Bonjour ${customerName ?? 'Cher client'},\n\n"
        'Voici votre ticket de caisse chez *$shopName* :\n'
        'Réf : ${sale.ref}\n'
        'Date : ${Fmt.dateTime(sale.createdAt)}\n\n'
        'Articles :\n$itemsText\n'
        '----------------\n'
        '*TOTAL TTC : ${Fmt.currency(sale.totalTtc)}*\n\n'
        'Merci de votre confiance !';

    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    String? qrData,
  }) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Mon Magasin';
    final shopAddress = settings['shop_address'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final footer = settings['receipt_footer'] ?? 'Merci !';
    final logoPath = settings['shop_logo_path'];

    // Détermination de la largeur depuis les paramètres (80mm ou 58mm)
    final paperWidthStr = settings['printer_paper_width'] ?? '80';
    final int paperWidthChars = paperWidthStr == '58' ? 32 : 42;

    final logoImage = await _getLogoImage(path: logoPath);

    // --- Logique pour Windows (USB/Réseau via PDF) ---
    if (Platform.isWindows) {
      // ... existant ...
      if (_currentPrinterType == AppPrinterType.usb &&
          _connectedUsbPrinter != null) {
        try {
          final text = buildReceiptText(
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
            width: paperWidthChars,
          );

          final bytes = _buildEscPos(
            text: text,
            shopName: shopName,
            shopAddress: shopAddress,
            shopPhone: shopPhone,
            footer: footer,
            logo: logoImage,
            width: paperWidthChars,
            qrData: qrData,
          );
          return await _printUsbEscPos(bytes);
        } catch (e) {
          debugPrint("Erreur d'impression USB (Windows): $e");
          return false;
        }
      } else {
        // Fallback to system PDF printing if no USB thermal printer is configured
        try {
          final printerName = await _db.getSetting('printer_name');
          if (printerName == null || printerName.isEmpty) {
            return false;
          }

          final printers = await Printing.listPrinters();
          final selectedPrinter = printers.firstWhere(
            (p) => p.name == printerName,
          );

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
            logoPath: logoPath,
            qrData: qrData,
            paperWidth: paperWidthStr,
          );

          debugPrint(
            'PrinterService: Envoi du document vers ${selectedPrinter.name}',
          );
          return await Printing.directPrintPdf(
            printer: selectedPrinter,
            onLayout: (_) => pdfBytes,
          );
        } catch (e) {
          debugPrint('ERREUR CRITIQUE IMPRESSION WINDOWS (PDF): $e');
          return false;
        }
      }
    }

    // --- Logique pour Mobile (Bluetooth/ESC-POS) ---
    if (Platform.isAndroid || Platform.isIOS) {
      // Vérification immédiate du matériel Bluetooth
      if (!(await isBluetoothOn())) {
        debugPrint('PrinterService: Le matériel Bluetooth est désactivé.');
        return false;
      }

      // Sécurité supplémentaire : s'assurer que le BT est toujours connecté
      if (!isConnected || _currentPrinterType != AppPrinterType.bluetooth) {
        return false; // NEW
      }
      try {
        final text = buildReceiptText(
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
          width: paperWidthChars,
        );

        final bytes = _buildEscPos(
          text: text,
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          footer: footer,
          logo: logoImage, // Peut être null
          width: paperWidthChars,
          qrData: qrData,
        );

        // Vérification de sécurité avant envoi
        if (await _bluetooth.isConnected == false) {
          final reconnected = await connect(_connectedDevice?.address ?? '');
          if (!reconnected) return false;
        }

        // Correction : Envoi par paquets réels pour éviter la saturation du buffer (cause fréquente de crash/écran noir)
        final uint8Bytes = Uint8List.fromList(bytes);
        const int chunkSize = 512;
        for (int i = 0; i < uint8Bytes.length; i += chunkSize) {
          final end = (i + chunkSize < uint8Bytes.length)
              ? i + chunkSize
              : uint8Bytes.length;
          final chunk = uint8Bytes.sublist(i, end);
          await _bluetooth.writeBytes(chunk);
          // Petit délai pour laisser le temps au matériel de respirer
          await Future.delayed(const Duration(milliseconds: 20));
        }

        return await _bluetooth.isConnected ?? false;
      } catch (e) {
        debugPrint("Erreur d'impression Bluetooth: $e");
        return false;
      }
    }

    return false; // Plateforme non supportée
  }

  /// Imprime des étiquettes de prix
  Future<bool> printPriceLabels(List<Map<String, dynamic>> labels) async {
    if (Platform.isWindows) {
      // NEW
      if (_currentPrinterType == AppPrinterType.usb &&
          _connectedUsbPrinter != null) {
        // NEW
        try {
          final shopName = await _db.getSetting('shop_name') ?? 'Magasin';
          final List<int> bytes = [];
          for (var label in labels) {
            final qty = label['copies'] as int? ?? 1;
            for (int i = 0; i < qty; i++) {
              final text = _buildLabelText(label, shopName);
              final barcode = label['barcode'] as String?;
              bytes.addAll(
                _buildEscPos(
                  text: text,
                  shopName: shopName,
                  shopAddress: '',
                  shopPhone: '',
                  footer: '',
                  width: 32,
                  barcodeData: barcode,
                ),
              );
            }
          }
          return await _printUsbEscPos(bytes); // NEW
        } catch (e) {
          debugPrint('Erreur impression étiquettes USB (Windows): $e');
          return false;
        }
      } else {
        // Fallback to system PDF printing
        try {
          final printerName = await _db.getSetting('printer_name');
          if (printerName == null || printerName.isEmpty) {
            return false;
          }

          final printers = await Printing.listPrinters();
          final selectedPrinter = printers.firstWhere(
            (p) => p.name == printerName,
          );

          final pdfBytes = await _generateLabelsPdf(labels);
          return await Printing.directPrintPdf(
            printer: selectedPrinter,
            onLayout: (_) => pdfBytes,
          );
        } catch (e) {
          debugPrint('Erreur impression étiquettes Windows (PDF): $e');
          return false;
        }
      }
    }

    if (Platform.isAndroid && isConnected) {
      // Pour thermal Bluetooth, on imprime une séquence d'étiquettes
      final shopName = await _db.getSetting('shop_name') ?? 'Magasin';
      final List<int> bytes = [];
      for (var label in labels) {
        final qty = label['copies'] as int? ?? 1;
        for (int i = 0; i < qty; i++) {
          final text = _buildLabelText(label, shopName);
          final barcode = label['barcode'] as String?;
          bytes.addAll(
            _buildEscPos(
              text: text,
              shopName: shopName,
              shopAddress: '',
              shopPhone: '',
              footer: '',
              width: 32,
              barcodeData: barcode,
            ),
          );
        }
      }
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      return true;
    } // NEW
    return false;
  }

  /// Imprime un rapport textuel (ex: Clôture de caisse)
  Future<bool> printReport(String text, {String? qrData}) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Magasin';
    final shopAddress = settings['shop_address'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final footer = settings['receipt_footer'] ?? '';
    final logoPath = settings['shop_logo_path'];

    final logoImage = await _getLogoImage(path: logoPath);

    if (Platform.isWindows) {
      // NEW
      if (_currentPrinterType == AppPrinterType.usb &&
          _connectedUsbPrinter != null) {
        // NEW
        try {
          final bytes = _buildEscPos(
            text: text,
            shopName: shopName,
            shopAddress: shopAddress,
            shopPhone: shopPhone,
            footer: footer,
            width: 42,
            logo: logoImage,
            qrData: qrData,
          );
          return await _printUsbEscPos(bytes); // NEW
        } catch (e) {
          debugPrint('Erreur impression rapport USB (Windows): $e');
          return false;
        }
      } else {
        // Fallback to system PDF printing
        try {
          final printerName = await _db.getSetting('printer_name');
          if (printerName == null || printerName.isEmpty) {
            return false;
          }

          final printers = await Printing.listPrinters();
          final selectedPrinter = printers.firstWhere(
            (p) => p.name == printerName,
          );

          final pdfBytes = await generateReportPdfBytes(
            text,
            useReceiptFormat: true,
            qrData: qrData,
          );
          return await Printing.directPrintPdf(
            printer: selectedPrinter,
            onLayout: (_) => pdfBytes,
          );
        } catch (e) {
          debugPrint('Erreur impression rapport Windows (PDF): $e');
          return false;
        }
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
        logo: logoImage,
        qrData: qrData,
      );
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      return true;
    } // NEW
    return false;
  }

  // NEW: Method to print ESC/POS bytes to USB printer
  Future<bool> _printUsbEscPos(List<int> bytes) async {
    if (_connectedUsbPrinter == null) {
      debugPrint('Aucune imprimante USB connectée.');
      return false;
    }
    try {
      await _printerManager.send(
        type: pos_printer.PrinterType.usb,
        bytes: bytes,
      );
      return true;
    } catch (e) {
      debugPrint("Erreur lors de l'écriture sur l'imprimante USB: $e");
      // Réinitialise l'état pour forcer une nouvelle découverte au prochain essai
      _connectedUsbPrinter = null;
      return false;
    }
  }

  /// Génère les bytes d'un rapport au format PDF.
  Future<Uint8List> generateReportPdfBytes(
    String text, {
    bool useReceiptFormat = false,
    List<String>? tableHeaders,
    List<List<String>>? tableData,
    String? qrData,
  }) async {
    final settings = await _db.getAllSettings();
    final shopName = settings['shop_name'] ?? 'Mon Magasin';
    final shopAddress = settings['shop_address'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final footer = settings['receipt_footer'] ?? '';

    // Chargement des polices personnalisées
    final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');

    // On augmente la taille du logo pour le format A4 (100px au lieu de 60px par défaut)
    final logoPdfWidget = await _getLogoPdfWidget(
      height: useReceiptFormat ? 60 : 100,
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(fontData),
        bold: pw.Font.ttf(fontBoldData),
      ),
    );

    // Utiliser le format A4 pour un téléchargement, ou le format ticket pour l'impression directe.
    final pageFormat = useReceiptFormat
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: useReceiptFormat
              ? pw.CrossAxisAlignment.start
              : pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            // --- Design spécifique pour format A4 (Documents partagés) ---
            if (!useReceiptFormat) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoPdfWidget != null) logoPdfWidget,
                  if (logoPdfWidget != null) pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (shopAddress.isNotEmpty)
                        pw.Text(
                          shopAddress,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      if (shopPhone.isNotEmpty)
                        pw.Text(
                          'Tél: $shopPhone',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
            ] else ...[
              // --- Design compact pour Reçu thermique ---
              if (logoPdfWidget != null) pw.Center(child: logoPdfWidget),
              if (logoPdfWidget != null) pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (shopAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    shopAddress,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Tél: $shopPhone',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
            ],

            pw.SizedBox(height: useReceiptFormat ? 15 : 30),

            // Affichage du texte d'introduction (références, etc.)
            pw.Text(
              text,
              style: pw.TextStyle(
                font: pw
                    .Font.courier(), // Indispensable pour garder l'alignement des colonnes
                fontSize: useReceiptFormat ? 10 : 12,
                lineSpacing: 1.2,
              ),
            ),

            pw.SizedBox(height: 15),

            // Génération du tableau si les données sont fournies
            if (tableHeaders != null && tableData != null)
              pw.TableHelper.fromTextArray(
                headers: tableHeaders,
                data: tableData,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  1: pw.Alignment.centerRight, // Quantité
                  2: pw.Alignment.centerRight, // P.U.
                  3: pw.Alignment.centerRight, // Total
                },
              ),

            if (qrData != null) ...[
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: useReceiptFormat ? 80 : 120,
                  height: useReceiptFormat ? 80 : 120,
                ),
              ),
            ],

            if (!useReceiptFormat) pw.Spacer(),
            pw.Center(
              child: pw.Text(
                footer,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Centralise la logique de génération, sauvegarde et partage de rapports PDF.
  Future<void> sharePdfReport({
    required String fileName,
    required String introText,
    required String shareMessage,
    required String subject,
    List<String>? tableHeaders,
    List<List<String>>? tableData,
    String? qrData,
  }) async {
    // 1. Générer les octets du PDF (format A4 par défaut pour le partage)
    final pdfBytes = await generateReportPdfBytes(
      introText,
      useReceiptFormat: false,
      tableHeaders: tableHeaders,
      tableData: tableData,
      qrData: qrData,
    );

    // 2. Sauvegarder dans un fichier temporaire
    final tempDir = await getTemporaryDirectory();
    final cleanName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final filePath = '${tempDir.path}/$cleanName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    // 3. Déclencher le menu de partage système
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(filePath, name: '$cleanName.pdf', mimeType: 'application/pdf'),
        ],
        subject: subject,
        text: shareMessage,
      ),
    );
  }

  /// Affiche l'aperçu avant impression/partage (Utilise le dialogue système).
  Future<void> previewPdfReport({
    required String introText,
    required String title,
    List<String>? tableHeaders,
    List<List<String>>? tableData,
    String? qrData,
  }) async {
    final pdfBytes = await generateReportPdfBytes(
      introText,
      useReceiptFormat: false,
      tableHeaders: tableHeaders,
      tableData: tableData,
      qrData: qrData,
    );

    // layoutPdf ouvre l'aperçu natif (Print Preview) sur toutes les plateformes
    await Printing.layoutPdf(onLayout: (format) => pdfBytes, name: title);
  }

  List<int> _buildEscPos({
    required String text,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String footer,
    img.Image? logo,
    String? qrData,
    String? barcodeData,
    required int width,
  }) {
    // Commandes ESC/POS de base
    const esc = 0x1B;
    const gs = 0x1D;
    const lf = 0x0A;

    final List<int> bytes = [];

    void add(List<int> data) => bytes.addAll(data);

    // CORRECTION : Encodage Latin1 pour gérer les caractères spéciaux sans crash
    void addText(String s) {
      try {
        bytes.addAll(latin1.encode(s));
      } catch (_) {
        bytes.addAll(s.codeUnits); // Fallback
      }
    }

    void newLine([int n = 1]) => bytes.addAll(List.filled(n, lf));
    void separator() => addText('-' * width);

    // Init
    add([esc, 0x40]); // Reset

    // Sélection de la table de caractères (16 = WPC1252 / Latin-1)
    // Indispensable sur Windows pour éviter les caractères étranges (mojibake)
    add([esc, 0x74, 0x10]);

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

    if (shopAddress.isNotEmpty) {
      addText(shopAddress);
      newLine();
    }
    if (shopPhone.isNotEmpty) {
      addText('Tél: $shopPhone');
      newLine();
    }
    newLine();

    // Corps du reçu (aligné gauche)
    add([esc, 0x61, 0x00]);
    separator();
    newLine();
    addText(text);
    separator();
    newLine();

    if (barcodeData != null && barcodeData.isNotEmpty) {
      add([esc, 0x61, 0x01]); // Centrer
      add(_generateEscPosBarcode(barcodeData));
      newLine();
    }

    if (qrData != null) {
      add([esc, 0x61, 0x01]); // Centrer
      add(_generateEscPosQrCode(qrData));
      newLine();
    }

    // Pied de page centré
    add([esc, 0x61, 0x01]);
    newLine();
    addText(footer);
    newLine(3);

    // Cut
    add([gs, 0x56, 0x41, 0x03]);

    return bytes;
  }

  /// Génère les commandes ESC/POS pour un QR Code (Standard GS ( k)
  List<int> _generateEscPosQrCode(String data) {
    final List<int> bytes = [];
    final List<int> content = data.codeUnits;
    final int pL = (content.length + 3) % 256;
    final int pH = (content.length + 3) ~/ 256;

    // 1. Select the model (Model 2)
    bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // 2. Set size of module (size 6)
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]);
    // 3. Set error correction level (Level L)
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30]);
    // 4. Store the data in the symbol storage area
    bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    bytes.addAll(content);
    // 5. Print the symbol data
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

    return bytes;
  }

  /// Génère les commandes ESC/POS pour un Code-barres 1D (CODE128)
  List<int> _generateEscPosBarcode(String data) {
    final List<int> bytes = [];
    // 1. Position du texte HRI (sous le code-barres pour lecture humaine)
    bytes.addAll([0x1D, 0x48, 0x02]);
    // 2. Hauteur du code-barres (env. 60 dots)
    bytes.addAll([0x1D, 0x68, 60]);
    // 3. Largeur du module (épaisseur des barres, 2 est un bon compromis)
    bytes.addAll([0x1D, 0x77, 0x02]);
    // 4. Impression du code-barres (CODE128 - Système B)
    // GS k m n d1...dn (m=73 pour CODE128)
    bytes.addAll([0x1D, 0x6B, 73, data.length]);
    bytes.addAll(data.codeUnits);

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
    img.Image resized;
    try {
      resized = img.copyResize(image, width: logoTargetWidth);
    } catch (e) {
      return []; // Si le redimensionnement échoue, on ignore le logo pour éviter le crash
    }
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
      final sliceHeight = (imgHeight - offset) > 255
          ? 255
          : (imgHeight - offset);

      // Définir la largeur et la hauteur de la tranche
      bytes.addAll([imgWidth % 256, imgWidth ~/ 256]);
      bytes.addAll([sliceHeight % 256, sliceHeight ~/ 256]);

      // Générer les données de la tranche en format colonne
      for (int x = 0; x < imgWidth; x++) {
        for (int y = 0; y < sliceHeight; y += 8) {
          int byte = 0;
          for (int bit = 0; bit < 8; bit++) {
            if ((y + bit) < sliceHeight) {
              // Sécurisation de l'accès aux pixels pour les versions 4.x de la lib 'image'
              final pixel = mono.getPixel(x, offset + y + bit);
              if (pixel.luminance < 128) {
                // Compatibilité image 4.x
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
    String? qrData,
    String paperWidth = '80',
  }) async {
    final doc = pw.Document();
    final double widthMm = double.tryParse(paperWidth) ?? 80.0;
    final pageFormat = PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 3 * PdfPageFormat.mm,
    );

    // Charger le logo si le chemin est fourni
    final logoWidget = await _getLogoPdfWidget(path: logoPath, height: 80);

    // Charger une version plus grande pour le filigrane
    final watermarkWidget = await _getLogoPdfWidget(
      path: logoPath,
      height: 200,
    );

    // Note: pour une police monospace, il faudrait l'ajouter aux assets et la charger ici.
    // final font = pw.Font.ttf(await rootBundle.load("assets/fonts/RobotoMono-Regular.ttf"));

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          // Le texte brut est généré par la méthode existante, on le réutilise pour le PDF.
          final receiptText = buildReceiptText(
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
            width: 48, // Largeur de caractères pour PDF
          );

          return pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              // --- COUCHE FILIGRANE (Watermark) ---
              if (watermarkWidget != null)
                pw.Opacity(
                  opacity: 0.08, // Très léger pour ne pas gêner la lecture
                  child: pw.Transform.rotate(
                    angle: -0.5, // Inclinaison de style (environ 30 degrés)
                    child: watermarkWidget,
                  ),
                ),

              // --- COUCHE CONTENU DU TICKET ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // En-tête
                  if (logoWidget != null) pw.Center(child: logoWidget),
                  if (logoWidget != null) pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (shopAddress.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        shopAddress,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  if (shopPhone.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        'Tél: $shopPhone',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
                  pw.SizedBox(height: 5),

                  // Corps du reçu
                  pw.Text(
                    receiptText,
                    style: pw.TextStyle(
                      font: pw.Font.courier(),
                      fontSize: 10,
                      lineSpacing: 1.5,
                    ),
                  ),

                  // Signature Fiscale (QR Code)
                  if (qrData != null) ...[
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 60,
                        height: 60,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Center(
                      child: pw.Text(
                        'Signature Fiscale: ${qrData.substring(0, 8)}...',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ],

                  // Pied de page
                  pw.SizedBox(height: 5),
                  pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      footer,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Helper pour charger le logo pour l'impression PDF
  Future<pw.Widget?> _getLogoPdfWidget({
    String? path,
    double height = 80,
  }) async {
    final logoPath = path ?? await _db.getSetting('shop_logo_path');
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.Image(pw.MemoryImage(bytes), height: height);
      }
    }
    return null;
  }

  /// Helper pour charger le logo pour l'impression ESC/POS
  Future<img.Image?> _getLogoImage({String? path}) async {
    final logoPath = path ?? await _db.getSetting('shop_logo_path');
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Utilisation de compute pour décoder l'image sans bloquer l'UI
        return compute(img.decodeImage, bytes);
      }
    }
    return null;
  }

  Future<Uint8List> _generateLabelsPdf(
    List<Map<String, dynamic>> labels,
  ) async {
    final doc = pw.Document();
    final shopName = await _db.getSetting('shop_name') ?? 'Magasin';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) => [
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: labels.expand((l) {
              return List.generate(
                l['copies'] as int,
                (_) => _buildPdfLabel(l, shopName),
              );
            }).toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _buildPdfLabel(Map<String, dynamic> data, String shopName) {
    return pw.Container(
      width: 60 * PdfPageFormat.mm,
      height: 38 * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            shopName,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
          pw.Text(
            data['name'],
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            maxLines: 2,
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            Fmt.currency(data['price'] as double),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          if (data['barcode'] != null && (data['barcode'] as String).isNotEmpty)
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: data['barcode'],
              height: 8 * PdfPageFormat.mm,
              drawText: false,
            ),
        ],
      ),
    );
  }

  String _buildLabelText(Map<String, dynamic> data, String shopName) {
    final buf = StringBuffer();
    buf.writeln(data['name'].toUpperCase());
    buf.writeln('PRIX: ${Fmt.currency(data['price'] as double)}');
    if (data['barcode'] != null) buf.writeln('REF: ${data['barcode']}');
    return buf.toString();
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
      final n = v
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
            (m) => '${m[1]} ',
          );
      return '$n $currency';
    }

    buf.writeln('RAPPORT DE CLOTURE DE CAISSE');
    buf.writeln();
    buf.writeln(
      'Session du: ${session.startedAt.day}/${session.startedAt.month}/${session.startedAt.year}',
    );
    buf.writeln(
      'De: ${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')} à ${session.endedAt?.hour.toString().padLeft(2, '0')}:${session.endedAt?.minute.toString().padLeft(2, '0')}',
    );
    buf.writeln('Utilisateur: $userName');
    buf.writeln('-' * width);

    buf.writeln(padLeft('ATTENDU', width));
    buf.writeln(
      pad('Fond de caisse', 30) +
          padLeft(fmt(session.startingCash), width - 30),
    );

    final cashSales = payments
        .where((p) => p.method == 'cash')
        .fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);
    buf.writeln(
      pad('Ventes (espèces)', 30) + padLeft(fmt(cashSales), width - 30),
    );
    buf.writeln(padLeft('-' * 12, width));
    buf.writeln(
      pad('TOTAL ATTENDU', 30) +
          padLeft(fmt(session.expectedCash ?? 0), width - 30),
    );
    buf.writeln();

    buf.writeln(padLeft('COMPTE', width));
    buf.writeln(
      pad('Total compté', 30) +
          padLeft(fmt(session.endingCash ?? 0), width - 30),
    );
    buf.writeln(
      pad('ECART', 30) + padLeft(fmt(session.discrepancy ?? 0), width - 30),
    );
    buf.writeln();

    buf.writeln(padLeft('AUTRES PAIEMENTS', width));
    final otherPayments = payments
        .where((p) => p.method != 'cash')
        .fold<Map<String, double>>({}, (map, p) {
          map[p.method] = (map[p.method] ?? 0) + p.amount - p.changeGiven;
          return map;
        });

    for (final entry in otherPayments.entries) {
      buf.writeln(
        pad(_fmtMethod(entry.key), 30) + padLeft(fmt(entry.value), width - 30),
      );
    }
    buf.writeln();

    return buf.toString();
  }

  /// Générer le texte structuré d'un bon de commande
  static String buildPurchaseOrderReport({
    required PurchaseOrder po,
    required Supplier supplier,
    required List<PurchaseOrderItemWithProduct> items,
    required String shopName,
    int width = 42,
  }) {
    final buf = StringBuffer();
    String pad(String s, int len) => s.padRight(len);
    String padLeft(String s, int len) => s.padLeft(len);

    buf.writeln('BON DE COMMANDE');
    buf.writeln('Référence: ${po.ref}');
    buf.writeln('Date: ${Fmt.dateTime(po.createdAt)}');
    buf.writeln('Statut: ${po.status.toUpperCase()}');
    buf.writeln('-' * width);
    buf.writeln('FOURNISSEUR: ${supplier.name}');
    if (supplier.phone != null) buf.writeln('Tél: ${supplier.phone}');
    buf.writeln('MAGASIN: $shopName');
    buf.writeln('-' * width);
    buf.writeln();
    buf.writeln(
      '${pad("Article", 22)}${padLeft("Qté", 6)}${padLeft("P.U.", width - 28)}',
    );
    buf.writeln('-' * width);

    for (final item in items) {
      final name = item.product.name.length > 22
          ? item.product.name.substring(0, 22)
          : item.product.name;
      buf.writeln(
        pad(name, 22) +
            padLeft('${item.item.quantity}', 6) +
            padLeft(Fmt.currency(item.item.unitCost), width - 28),
      );
    }

    buf.writeln('-' * width);
    buf.writeln(
      pad('TOTAL ESTIMÉ:', 25) +
          padLeft(Fmt.currency(po.totalAmount), width - 25),
    );

    return buf.toString();
  }

  /// Générer le texte d'un ticket de dépense individuel (Justificatif)
  static String buildExpenseTicket({
    required Expense expense,
    required String userName,
    int width = 42,
  }) {
    final buf = StringBuffer();
    String pad(String s, int len) => s.padRight(len);
    String padLeft(String s, int len) => s.padLeft(len);

    buf.writeln('   *** JUSTIFICATIF DE DEPENSE ***');
    buf.writeln();
    buf.writeln('Date: ${Fmt.dateTime(expense.date)}');
    buf.writeln('Agent: $userName');
    buf.writeln('-' * width);
    buf.writeln();
    buf.writeln('CATEGORIE: ${expense.category}');
    buf.writeln('DESCRIPTION:');
    buf.writeln(expense.description);
    buf.writeln();
    buf.writeln('-' * width);
    buf.writeln(
      pad('MONTANT:', 20) + padLeft(Fmt.currency(expense.amount), width - 20),
    );
    buf.writeln();
    buf.writeln('Signature :');
    buf.writeln('\n\n\n');
    return buf.toString();
  }

  /// Générer le texte d'un reçu pour un paiement groupé de dettes
  static String buildBulkPaymentTicket({
    required Customer customer,
    required double totalPaid,
    required String paymentMethod,
    required List<String> saleRefs,
    required String userName,
    int width = 42,
  }) {
    final buf = StringBuffer();

    buf.writeln('   *** RECU DE PAIEMENT DETTES ***');
    buf.writeln();
    buf.writeln('Date: ${Fmt.dateTime(DateTime.now())}');
    buf.writeln('Client: ${customer.name}');
    buf.writeln('Agent: $userName');
    buf.writeln('-' * width);
    buf.writeln();
    buf.writeln('MONTANT VERSE: ${Fmt.currency(totalPaid)}');
    buf.writeln('MODE: ${_fmtMethod(paymentMethod)}');
    buf.writeln();
    buf.writeln('VENTES CONCERNEES:');
    for (final ref in saleRefs) {
      buf.writeln(' - $ref');
    }
    buf.writeln();
    buf.writeln('-' * width);
    buf.writeln();
    buf.writeln('Signature :');
    buf.writeln('\n\n\n');
    return buf.toString();
  }

  /// Générer le texte du rapport des pertes d'inventaire (Défectueux, Obsolètes, Périmés)
  static String buildInventoryLossReport({
    required InventorySession session,
    required List<InventoryLine> lines,
    required String userName,
    int width = 42,
  }) {
    final buf = StringBuffer();
    String pad(String s, int len) => s.padRight(len);
    String padLeft(String s, int len) => s.padLeft(len);

    final losses = lines
        .where(
          (l) => l.defectiveQty > 0 || l.obsoleteQty > 0 || l.expiredQty > 0,
        )
        .toList();

    buf.writeln('RAPPORT DES PERTES D\'INVENTAIRE');
    buf.writeln('Référence: ${session.ref}');
    buf.writeln('Date: ${Fmt.dateTime(session.startedAt)}');
    if (session.completedAt != null) {
      buf.writeln('Clôturé le: ${Fmt.dateTime(session.completedAt!)}');
    }
    buf.writeln('Utilisateur: $userName');
    buf.writeln('-' * width);
    buf.writeln();

    if (losses.isEmpty) {
      buf.writeln('Aucune perte spécifique signalée lors de cet inventaire.');
    } else {
      // En-tête : Article | Déf | Obs | Pér | Total
      buf.writeln(
        '${pad("Article", 18)}${padLeft("Déf.", 6)}${padLeft("Obs.", 6)}${padLeft("Pér.", 6)}${padLeft("Tot.", width - 36)}',
      );
      buf.writeln('-' * width);

      for (final l in losses) {
        final name = l.productName.length > 17
            ? '${l.productName.substring(0, 16)}.'
            : l.productName;
        final totalLoss = l.defectiveQty + l.obsoleteQty + l.expiredQty;
        buf.writeln(
          pad(name, 18) +
              padLeft('${l.defectiveQty}', 6) +
              padLeft('${l.obsoleteQty}', 6) +
              padLeft('${l.expiredQty}', 6) +
              padLeft('$totalLoss', width - 36),
        );
      }
      buf.writeln('-' * width);

      final int totalDef = losses.fold<int>(
        0,
        (sum, l) => sum + (l.defectiveQty),
      );
      final int totalObs = losses.fold<int>(
        0,
        (sum, l) => sum + (l.obsoleteQty),
      );
      final int totalExp = losses.fold<int>(
        0,
        (sum, l) => sum + (l.expiredQty),
      );
      final grandTotal = totalDef + totalObs + totalExp;

      buf.writeln(
        pad('TOTAL PERTES:', 18) +
            padLeft('$totalDef', 6) +
            padLeft('$totalObs', 6) +
            padLeft('$totalExp', 6) +
            padLeft('$grandTotal', width - 36),
      );
    }
    return buf.toString();
  }

  /// Générer le texte du rapport d'inventaire
  static String buildInventoryReport({
    required InventorySession session,
    required List<InventoryLine> lines,
    required String userName,
    int width = 42, // pour texte, PDF ignore
  }) {
    final buf = StringBuffer();
    String pad(String s, int len) => s.padRight(len);
    String padLeft(String s, int len) => s.padLeft(len);

    final discrepancies = lines.where((l) => (l.difference ?? 0) != 0).toList();

    buf.writeln('RAPPORT D\'INVENTAIRE');
    buf.writeln('Référence: ${session.ref}');
    buf.writeln('Date: ${Fmt.dateTime(session.startedAt)}');
    if (session.completedAt != null) {
      buf.writeln('Clôturé le: ${Fmt.dateTime(session.completedAt!)}');
    }
    buf.writeln('Utilisateur: $userName');
    buf.writeln('-' * width);
    buf.writeln();
    buf.writeln('RÉSUMÉ');
    buf.writeln(
      pad('Produits inventoriés:', 25) +
          padLeft('${session.totalProducts}', width - 25),
    );
    buf.writeln(
      pad('Produits avec écart:', 25) +
          padLeft('${discrepancies.length}', width - 25),
    );
    buf.writeln();

    if (discrepancies.isNotEmpty) {
      buf.writeln('DÉTAIL DES ÉCARTS');
      buf.writeln('-' * width);
      buf.writeln(
        pad('Produit', 20) +
            padLeft('Théo', 6) +
            padLeft('Cpté', 6) +
            padLeft('Écart', width - 32),
      );

      for (final line in discrepancies) {
        final name = line.productName.length > 18
            ? '${line.productName.substring(0, 17)}.'
            : line.productName;
        final diff = line.difference ?? 0;
        final diffStr = diff > 0 ? '+$diff' : '$diff';
        buf.writeln(
          pad(name, 20) +
              padLeft('${line.expectedQty}', 6) +
              padLeft('${line.countedQty}', 6) +
              padLeft(diffStr, width - 32),
        );
      }
      buf.writeln('-' * width);
    }
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
      final n = v
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
            (m) => '${m[1]} ',
          );
      return '$n $sym';
    }

    buf.writeln(
      'Date: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
    );
    buf.writeln('N° $ref');
    buf.writeln('Caissier: $cashierName');
    if (customerName != null) buf.writeln('Client: $customerName');
    buf.writeln();

    // En-têtes colonnes
    buf.writeln(
      '${pad("Article", 22)}${pad("Qté", 5, right: true)}${pad("Total", width - 27, right: true)}',
    );
    buf.writeln('-' * width);

    for (final item in items) {
      final name = item['name'] as String;
      final barcode = item['barcode'] as String?;
      final qty = item['qty'] as int;
      final total = item['total'] as double;
      final price = item['price'] as double;

      buf.writeln(pad(name.length > 22 ? name.substring(0, 22) : name, 22));
      if (barcode != null) buf.writeln('  ($barcode)');
      buf.writeln(
        '  ${pad(price.toStringAsFixed(0), 18)}${pad(qty.toString(), 5, right: true)}${pad(fmt(total), width - 23, right: true)}',
      );
    }

    buf.writeln('-' * width);

    if (totalHt != totalTtc) {
      buf.writeln(
        '${pad("Sous-total HT", 30)}${pad(fmt(totalHt), width - 30, right: true)}',
      );
      buf.writeln(
        '${pad("TVA", 30)}${pad(fmt(totalTax), width - 30, right: true)}',
      );
    }
    if (discountAmount > 0) {
      buf.writeln(
        '${pad("Remise", 30)}${pad("-${fmt(discountAmount)}", width - 30, right: true)}',
      );
    }
    buf.writeln('-' * width);
    buf.writeln(
      '${pad("TOTAL TTC", 30)}${pad(fmt(totalTtc), width - 30, right: true)}',
    );
    buf.writeln();
    buf.writeln(
      '${pad("Paiement (${_fmtMethod(paymentMethod)})", 30)}${pad(fmt(amountPaid), width - 30, right: true)}',
    );
    if (changeGiven > 0) {
      buf.writeln(
        '${pad("Rendu monnaie", 30)}${pad(fmt(changeGiven), width - 30, right: true)}',
      );
    }
    buf.writeln();

    return buf.toString();
  }

  static String _fmtMethod(String m) {
    switch (m) {
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte';
      case 'mobile_money':
        return 'Mobile Money';
      case 'wave':
        return 'Wave';
      case 'orange_money':
        return 'Orange Money';
      default:
        return m;
    }
  }
}
