import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/printer_settings.dart';

/// Builds ESC/POS byte commands from a Bill object.
class EscPosBuilder {
  /// Chuyển ký tự tiếng Việt có dấu → ASCII không dấu.
  /// ESC/POS printers dùng Latin-1 không hỗ trợ Unicode tiếng Việt.
  static String _vi(String text) {
    const map = {
      // a
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
      // e
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
      // i
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
      // o
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
      // u
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
      // y
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
      // d
      'đ': 'd', 'Đ': 'D',
    };
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      buf.write(map[c] ?? c);
    }
    return buf.toString();
  }
  static Future<List<int>> buildBill(
    Bill bill,
    PrinterSettings settings,
  ) async {
    final profile = await CapabilityProfile.load();
    final effectivePaperWidth = bill.paperWidth ?? settings.paperWidth;
    final paperSize =
        effectivePaperWidth == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);

    List<int> bytes = [];

    // ── Header ──────────────────────────────────────────────────
    bytes += generator.text(
      _vi(bill.shopName),
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    if (bill.shopAddress != null && bill.shopAddress!.isNotEmpty) {
      bytes += generator.text(
        _vi(bill.shopAddress!),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (bill.shopPhone != null && bill.shopPhone!.isNotEmpty) {
      bytes += generator.text(
        'DT: ${bill.shopPhone!}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.text(
      'HOA DON BAN HANG',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    final timeStr =
        DateFormat('dd/MM/yyyy HH:mm').format(bill.printTime);
    bytes += generator.text(
      'In luc: $timeStr',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr();

    // ── Info ────────────────────────────────────────────────────
    bytes += generator.text('Nhan vien: ${_vi(bill.staffName)}');
    bytes += generator.text('Khach hang: ${_vi(bill.customerName)}');
    bytes += generator.text('Ban: ${bill.tableNumber}');

    bytes += generator.hr();

    // ── Column header ───────────────────────────────────────────
    final colWidths = _columnWidths(effectivePaperWidth);
    bytes += generator.row([
      PosColumn(
        text: 'Mat hang',
        width: colWidths[0],
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'SL',
        width: colWidths[1],
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'T.Tien',
        width: colWidths[2],
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr(ch: '-');

    // ── Items ───────────────────────────────────────────────────
    final numFmt = NumberFormat('#,###', 'vi_VN');
    for (final item in bill.items) {
      final totalStr = numFmt.format(item.total.toInt());
      final nameMaxLen = _nameMaxLen(effectivePaperWidth);
      final displayName = _vi(item.displayName);
      if (displayName.length > nameMaxLen) {
        bytes += generator.text(displayName);
        bytes += generator.row([
          PosColumn(text: '', width: colWidths[0]),
          PosColumn(
            text: '${item.quantity}',
            width: colWidths[1],
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: totalStr,
            width: colWidths[2],
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: displayName, width: colWidths[0]),
          PosColumn(
            text: '${item.quantity}',
            width: colWidths[1],
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: totalStr,
            width: colWidths[2],
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    bytes += generator.hr();

    // ── Note ────────────────────────────────────────────────────
    if (bill.note.isNotEmpty) {
      bytes += generator.text('Ghi chu: ${_vi(bill.note)}');
    }

    // ── Adjustment ──────────────────────────────────────────────
    if (bill.adjustment != 0) {
      final adjLabel = bill.adjustNote.isNotEmpty
          ? _vi(bill.adjustNote)
          : (bill.adjustment > 0 ? 'Phu thu' : 'Giam gia');
      final adjStr =
          '${bill.adjustment > 0 ? '+' : ''}${numFmt.format(bill.adjustment.toInt())}';
      bytes += generator.row([
        PosColumn(text: adjLabel, width: 8),
        PosColumn(
          text: adjStr,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // ── Total ───────────────────────────────────────────────────
    final totalStr = numFmt.format(bill.finalTotal.toInt());
    bytes += generator.row([
      PosColumn(
        text: 'Tong:',
        width: 8,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: totalStr,
        width: 4,
        styles: const PosStyles(
          bold: true,
          align: PosAlign.right,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr();

    // ── Footer ──────────────────────────────────────────────────
    bytes += generator.feed(1);
    bytes += generator.text(
      _vi(bill.footer),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static List<int> _columnWidths(int paperWidth) {
    if (paperWidth == 80) {
      return [7, 2, 3];
    }
    return [6, 2, 4];
  }

  static int _nameMaxLen(int paperWidth) {
    return paperWidth == 80 ? 20 : 14;
  }
}
