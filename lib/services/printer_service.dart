import 'dart:async';
import 'dart:io';
import '../models/bill_model.dart';
import '../models/kitchen_ticket_model.dart';
import '../models/printer_settings.dart';
import 'escpos_builder.dart';

enum PrintStatus { idle, printing, success, error }

class PrintResult {
  final bool success;
  final String message;

  const PrintResult({required this.success, required this.message});
}

/// Handles sending ESC/POS bytes to a printer.
/// Supports: Network (TCP/IP) on all platforms.
/// Bluetooth is handled via flutter_thermal_printer (separate flow).
class PrinterService {
  /// Print over TCP/IP network socket.
  /// Works on: Android, iOS, macOS, Windows.
  static Future<PrintResult> printViaNetwork({
    required Bill bill,
    required PrinterSettings settings,
  }) async {
    try {
      final bytes = await EscPosBuilder.buildBill(bill, settings);

      final socket = await Socket.connect(
        settings.ipAddress,
        settings.port,
        timeout: const Duration(seconds: 10),
      );

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return const PrintResult(success: true, message: 'In thành công!');
    } on SocketException catch (e) {
      return PrintResult(
        success: false,
        message: 'Không kết nối được máy in:\n${e.message}',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Lỗi khi in: $e',
      );
    }
  }

  /// Print kitchen ticket over TCP/IP network socket.
  static Future<PrintResult> printKitchenTicketViaNetwork({
    required KitchenTicket ticket,
    required PrinterSettings settings,
  }) async {
    try {
      final bytes = await EscPosBuilder.buildKitchenTicket(ticket, settings);

      final socket = await Socket.connect(
        settings.ipAddress,
        settings.port,
        timeout: const Duration(seconds: 10),
      );

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return const PrintResult(success: true, message: 'In phiếu chế biến thành công!');
    } on SocketException catch (e) {
      return PrintResult(
        success: false,
        message: 'Không kết nối được máy in:\n${e.message}',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Lỗi khi in phiếu chế biến: $e',
      );
    }
  }

  /// Returns raw ESC/POS bytes (for preview or Bluetooth sending).
  static Future<List<int>> buildBytes(
    Bill bill,
    PrinterSettings settings,
  ) async {
    return EscPosBuilder.buildBill(bill, settings);
  }

  /// In test code page: in toàn bộ byte 65–255 với code page được chọn.
  /// [codePageId] null = dùng code page mặc định của máy in.
  /// Các giá trị thường gặp: 0=PC437, 16=WPC1252, 36=CP1258(Vietnamese).
  static Future<PrintResult> printCodePageTest({
    required PrinterSettings settings,
    int? codePageId,
  }) async {
    try {
      final bytes = await EscPosBuilder.buildCodePageTest(
        settings,
        codePageId: codePageId,
      );

      final socket = await Socket.connect(
        settings.ipAddress,
        settings.port,
        timeout: const Duration(seconds: 10),
      );

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      final label = codePageId != null ? 'CP$codePageId' : 'default';
      return PrintResult(
        success: true,
        message: 'In test code page ($label) thanh cong!',
      );
    } on SocketException catch (e) {
      return PrintResult(
        success: false,
        message: 'Khong ket noi duoc may in:\n${e.message}',
      );
    } catch (e) {
      return PrintResult(success: false, message: 'Loi khi in: $e');
    }
  }
}
