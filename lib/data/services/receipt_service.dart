// ============================================================
//  Service d'impression Bluetooth ESC/POS
//  Compatible imprimantes thermiques : EPSON, Star, Xprinter...
// ============================================================

import 'dart:typed_data';
import 'package:flutter/services.dart';

// Commandes ESC/POS de base
class EscPos {
  static const esc = 0x1B;
  static const gs  = 0x1D;
  static const lf  = 0x0A;

  // Init imprimante
  static Uint8List init() => Uint8List.fromList([esc, 0x40]);

  // Alignement
  static Uint8List alignLeft()   => Uint8List.fromList([esc, 0x61, 0x00]);
  static Uint8List alignCenter() => Uint8List.fromList([esc, 0x61, 0x01]);
  static Uint8List alignRight()  => Uint8List.fromList([esc, 0x61, 0x02]);

  // Police
  static Uint8List boldOn()  => Uint8List.fromList([esc, 0x45, 0x01]);
  static Uint8List boldOff() => Uint8List.fromList([esc, 0x45, 0x00]);

  // Taille du texte
  static Uint8List normalSize()  => Uint8List.fromList([gs, 0x21, 0x00]);
  static Uint8List doubleWidth() => Uint8List.fromList([gs, 0x21, 0x20]);
  static Uint8List doubleHeight()=> Uint8List.fromList([gs, 0x21, 0x10]);
  static Uint8List doubleSize()  => Uint8List.fromList([gs, 0x21, 0x11]);

  // Saut de ligne
  static Uint8List feed({int lines = 1}) =>
      Uint8List.fromList(List.filled(lines, lf));

  // Découpe papier
  static Uint8List cut() => Uint8List.fromList([gs, 0x56, 0x41, 0x05]);

  // Texte encodé Latin-1 (compatible imprimantes basiques)
  static Uint8List text(String s) {
    // Pour Afrique : certaines imprimantes supportent UTF-8, d'autres Latin-1
    // On encode en Latin-1 avec fallback ASCII pour les caractères spéciaux
    final bytes = <int>[];
    for (final c in s.runes) {
      if (c < 128) {
        bytes.add(c);
      } else if (c < 256) {
        bytes.add(c); // Latin-1
      } else {
        bytes.add(0x3F); // '?' pour les caractères non supportés
      }
    }
    bytes.add(lf);
    return Uint8List.fromList(bytes);
  }

  // Ligne séparatrice
  static Uint8List separator({int width = 32, String char = '-'}) =>
      text(char * width);

  // Ligne avec deux colonnes (gauche + droite)
  static Uint8List twoColumn(String left, String right,
      {int width = 32}) {
    final spaces = width - left.length - right.length;
    final line =
        left + ' ' * (spaces > 0 ? spaces : 1) + right;
    return text(line);
  }
}

// ── BUILDER DE REÇU ──────────────────────────
class ReceiptBuilder {
  final _buf = <int>[];

  ReceiptBuilder add(Uint8List data) {
    _buf.addAll(data);
    return this;
  }

  Uint8List build() => Uint8List.fromList(_buf);
}

// ── GÉNÉRATEUR DE REÇU POS ───────────────────
class ReceiptGenerator {
  static const _width = 32; // colonnes pour papier 58mm / 48 pour 80mm

  static Uint8List generateSaleReceipt({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String saleRef,
    required DateTime saleDate,
    required List<ReceiptLine> items,
    required double subtotalHt,
    required double taxes,
    required double total,
    required double amountPaid,
    required double change,
    required String paymentMethod,
    String footer = 'Merci de votre visite !',
    String? customerName,
  }) {
    final b = ReceiptBuilder();

    // En-tête
    b.add(EscPos.init());
    b.add(EscPos.alignCenter());
    b.add(EscPos.boldOn());
    b.add(EscPos.doubleSize());
    b.add(EscPos.text(shopName));
    b.add(EscPos.normalSize());
    b.add(EscPos.boldOff());

    if (shopAddress.isNotEmpty) b.add(EscPos.text(shopAddress));
    if (shopPhone.isNotEmpty) b.add(EscPos.text('Tel: $shopPhone'));

    b.add(EscPos.feed());
    b.add(EscPos.separator(width: _width));

    // Infos vente
    b.add(EscPos.alignLeft());
    b.add(EscPos.text('Ref : $saleRef'));
    b.add(EscPos.text(_formatDate(saleDate)));
    if (customerName != null) b.add(EscPos.text('Client : $customerName'));

    b.add(EscPos.separator(width: _width));

    // En-tête colonnes
    b.add(EscPos.boldOn());
    b.add(EscPos.text(_col3('Article', 'Qté', 'Total', _width)));
    b.add(EscPos.boldOff());
    b.add(EscPos.separator(width: _width, char: '='));

    // Lignes articles
    for (final item in items) {
      // Nom produit (tronqué si trop long)
      final name = item.name.length > _width - 12
          ? '${item.name.substring(0, _width - 12)}...'
          : item.name;
      b.add(EscPos.text(_col3(
        name,
        'x${item.qty}',
        _formatAmount(item.lineTotal),
        _width,
      )));
      if (item.discountPct > 0) {
        b.add(EscPos.text('  Remise ${item.discountPct.toStringAsFixed(0)}%'));
      }
    }

    b.add(EscPos.separator(width: _width));

    // Totaux
    b.add(EscPos.twoColumn('Sous-total HT', _formatAmount(subtotalHt), width: _width));
    if (taxes > 0) {
      b.add(EscPos.twoColumn('Taxes', _formatAmount(taxes), width: _width));
    }

    b.add(EscPos.separator(width: _width, char: '='));
    b.add(EscPos.boldOn());
    b.add(EscPos.doubleHeight());
    b.add(EscPos.twoColumn('TOTAL', _formatAmount(total), width: _width));
    b.add(EscPos.normalSize());
    b.add(EscPos.boldOff());

    b.add(EscPos.feed());
    b.add(EscPos.twoColumn(_paymentLabel(paymentMethod),
        _formatAmount(amountPaid), width: _width));
    if (change > 0) {
      b.add(EscPos.twoColumn('Monnaie', _formatAmount(change), width: _width));
    }

    b.add(EscPos.separator(width: _width));

    // Pied de page
    b.add(EscPos.alignCenter());
    if (footer.isNotEmpty) {
      b.add(EscPos.feed());
      b.add(EscPos.text(footer));
    }

    b.add(EscPos.feed(lines: 3));
    b.add(EscPos.cut());

    return b.build();
  }

  // Colonnes 3 en mode texte
  static String _col3(String left, String mid, String right, int w) {
    const midLen = 4;
    final rightLen = right.length > 10 ? right.length : 10;
    final leftLen = w - midLen - rightLen - 2;
    final l = left.length > leftLen ? left.substring(0, leftLen) : left;
    final lPad = l.padRight(leftLen);
    final mPad = mid.padLeft(midLen);
    final rPad = right.padLeft(rightLen);
    return '$lPad $mPad $rPad';
  }

  static String _formatAmount(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F';

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _paymentLabel(String method) => switch (method) {
        'cash' => 'Espèces reçues',
        'card' => 'Carte bancaire',
        'mobile_money' => 'Mobile Money',
        'credit' => 'Crédit accordé',
        _ => 'Paiement',
      };
}

class ReceiptLine {
  final String name;
  final int qty;
  final double lineTotal;
  final double discountPct;
  const ReceiptLine({
    required this.name,
    required this.qty,
    required this.lineTotal,
    this.discountPct = 0,
  });
}

// ── SERVICE BLUETOOTH ────────────────────────
// NOTE: Utiliser flutter_bluetooth_serial pour Android
//       et flutter_blue_plus pour iOS/macOS
//
// Voici le patron d'utilisation :
//
// class BluetoothPrinterService {
//   BluetoothConnection? _connection;
//
//   Future<List<BluetoothDevice>> scanDevices() async {
//     return await FlutterBluetoothSerial.instance.getBondedDevices();
//   }
//
//   Future<void> connect(String address) async {
//     _connection = await BluetoothConnection.toAddress(address);
//   }
//
//   Future<void> print(Uint8List data) async {
//     if (_connection == null) throw Exception('Imprimante non connectée');
//     _connection!.output.add(data);
//     await _connection!.output.allSent;
//   }
//
//   Future<void> disconnect() async {
//     await _connection?.close();
//     _connection = null;
//   }
//
//   bool get isConnected => _connection?.isConnected ?? false;
// }
//
// ── UTILISATION ──────────────────────────────
//
// final receipt = ReceiptGenerator.generateSaleReceipt(
//   shopName: 'Mon Magasin',
//   shopAddress: 'Dakar, Sénégal',
//   shopPhone: '+221 77 000 00 00',
//   saleRef: 'VTE-20240315-00042',
//   saleDate: DateTime.now(),
//   items: cartItems.map((i) => ReceiptLine(
//     name: i.product.name,
//     qty: i.quantity,
//     lineTotal: i.lineTotal,
//     discountPct: i.discountPct,
//   )).toList(),
//   subtotalHt: state.subtotalHt,
//   taxes: state.totalTax,
//   total: state.total,
//   amountPaid: amountPaid,
//   change: change,
//   paymentMethod: 'cash',
//   footer: 'Merci de votre visite !',
// );
//
// await printerService.print(receipt);
