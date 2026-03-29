import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_model.dart';
import '../models/kitchen_ticket_model.dart';
import '../models/printer_settings.dart';
import '../models/remote_settings.dart';
import 'printer_service.dart';
import 'websocket_service.dart';

class AppState extends ChangeNotifier {
  Bill _bill = Bill.demo();
  PrinterSettings _settings = PrinterSettings();
  RemoteSettings _remoteSettings = const RemoteSettings();
  PrintStatus _printStatus = PrintStatus.idle;
  String _statusMessage = '';
  bool _isFetchingFromApi = false;

  Bill get bill => _bill;
  PrinterSettings get settings => _settings;
  RemoteSettings get remoteSettings => _remoteSettings;
  PrintStatus get printStatus => _printStatus;
  String get statusMessage => _statusMessage;
  bool get isFetchingFromApi => _isFetchingFromApi;

  late final WebSocketService wsService;

  AppState() {
    wsService = WebSocketService(this);
    _loadSettings();
  }

  void updateBill(Bill bill) {
    _bill = bill;
    notifyListeners();
  }

  void updateSettings(PrinterSettings settings) {
    _settings = settings;
    _saveSettings();
    notifyListeners();
  }

  void updateRemoteSettings(RemoteSettings settings) {
    _remoteSettings = settings;
    _saveRemoteSettings();
    wsService.configure(settings);
    notifyListeners();
  }

  void reconnectWs() {
    wsService.configure(_remoteSettings);
  }

  String get restaurantSlug => _remoteSettings.restaurantSlug;

  Future<void> printBill() async {
    _printStatus = PrintStatus.printing;
    _statusMessage = 'Đang gửi lệnh in...';
    notifyListeners();

    // Bill in tại lễ tân — dùng billIpAddress/billPort
    final billPrinterSettings = _settings.copyWith(
      ipAddress: _settings.billIpAddress,
      port: _settings.billPort,
    );
    final result = await PrinterService.printViaNetwork(
      bill: _bill,
      settings: billPrinterSettings,
    );

    _printStatus = result.success ? PrintStatus.success : PrintStatus.error;
    _statusMessage = result.message;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _printStatus = PrintStatus.idle;
    _statusMessage = '';
    notifyListeners();
  }

  /// Gọi khi nhận lệnh in từ WebSocket/API: cập nhật bill rồi in
  Future<void> printBillFromRemote(Bill bill) async {
    updateBill(bill);
    await printBill();
  }

  /// Gọi khi nhận lệnh in phiếu chế biến từ WebSocket
  Future<void> printKitchenTicketFromRemote(KitchenTicket ticket) async {
    _printStatus = PrintStatus.printing;
    _statusMessage = 'Đang in phiếu chế biến...';
    notifyListeners();

    final result = await PrinterService.printKitchenTicketViaNetwork(
      ticket: ticket,
      settings: _settings,
    );

    _printStatus = result.success ? PrintStatus.success : PrintStatus.error;
    _statusMessage = result.message;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _printStatus = PrintStatus.idle;
    _statusMessage = '';
    notifyListeners();
  }

  /// Gọi API để lấy lệnh in đang chờ (fallback khi mất WS)
  Future<void> fetchAndPrint() async {
    if (_isFetchingFromApi) return;
    if (!_remoteSettings.isConfigured) {
      _setStatus(PrintStatus.error, 'Chưa cấu hình địa chỉ máy chủ');
      await Future.delayed(const Duration(seconds: 3));
      _setStatus(PrintStatus.idle, '');
      return;
    }

    _isFetchingFromApi = true;
    _setStatus(PrintStatus.printing, 'Đang lấy lệnh in từ máy chủ...');

    try {
      final uri = Uri.parse(_remoteSettings.pendingUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> jobs = body is List ? body : (body['data'] as List? ?? []);

      if (jobs.isEmpty) {
        _isFetchingFromApi = false;
        _setStatus(PrintStatus.success, 'Không có lệnh in nào đang chờ');
        await Future.delayed(const Duration(seconds: 3));
        _setStatus(PrintStatus.idle, '');
        return;
      }

      int printed = 0;
      for (final job in jobs) {
        final data = (job['data'] ?? job) as Map<String, dynamic>;
        final requestId = job['requestId'] as String?;
        final event = job['event'] as String? ?? 'print_bill';
        try {
          if (event == 'print_kitchen') {
            final ticket = KitchenTicket.fromJson(data);
            final ref = ticket.requestedAt;
            if (ref != null && DateTime.now().difference(ref).abs().inSeconds > 60) {
              debugPrint('[API] Bỏ qua phiếu chế biến #${ticket.orderId} — quá 30 giây');
              if (requestId != null) _ackJob(requestId, 'printed');
              continue;
            }
            await printKitchenTicketFromRemote(ticket);
          } else {
            final bill = Bill.fromJson(data);
            await printBillFromRemote(bill);
          }
          printed++;
          if (requestId != null) _ackJob(requestId, 'printed');
        } catch (e) {
          debugPrint('[API] Failed to print job ($event): $e');
          if (requestId != null) _ackJob(requestId, 'error');
        }
      }

      _isFetchingFromApi = false;
      _setStatus(PrintStatus.success, 'Đã in $printed lệnh từ máy chủ');
      await Future.delayed(const Duration(seconds: 3));
      _setStatus(PrintStatus.idle, '');
    } catch (e) {
      _isFetchingFromApi = false;
      _setStatus(PrintStatus.error, 'Lỗi khi lấy lệnh in: $e');
      await Future.delayed(const Duration(seconds: 3));
      _setStatus(PrintStatus.idle, '');
    }
  }

  void _ackJob(String requestId, String status) {
    final uri = Uri.parse(_remoteSettings.ackUrl(requestId));
    http
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 5))
        .catchError((e) {
          debugPrint('[API] Ack failed: $e');
          return http.Response('', 500);
        });
  }

  void _setStatus(PrintStatus status, String message) {
    _printStatus = status;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = PrinterSettings();
    _settings = PrinterSettings(
      connectionType: PrinterConnectionType.values[
          prefs.getInt('connectionType') ?? defaults.connectionType.index],
      ipAddress: prefs.getString('ipAddress') ?? defaults.ipAddress,
      port: prefs.getInt('port') ?? defaults.port,
      billIpAddress: prefs.getString('billIpAddress') ?? defaults.billIpAddress,
      billPort: prefs.getInt('billPort') ?? defaults.billPort,
      paperWidth: prefs.getInt('paperWidth') ?? defaults.paperWidth,
      unicodeVietnamese: prefs.getBool('unicodeVietnamese') ?? defaults.unicodeVietnamese,
    );
    _remoteSettings = RemoteSettings(
      serverBaseUrl: prefs.getString('serverBaseUrl') ?? '',
      restaurantSlug: prefs.getString('restaurantSlug') ?? '',
      wsEnabled: prefs.getBool('wsEnabled') ?? false,
    );
    wsService.configure(_remoteSettings);
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('connectionType', _settings.connectionType.index);
    await prefs.setString('ipAddress', _settings.ipAddress);
    await prefs.setInt('port', _settings.port);
    await prefs.setString('billIpAddress', _settings.billIpAddress);
    await prefs.setInt('billPort', _settings.billPort);
    await prefs.setInt('paperWidth', _settings.paperWidth);
    await prefs.setBool('unicodeVietnamese', _settings.unicodeVietnamese);
  }

  Future<void> _saveRemoteSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverBaseUrl', _remoteSettings.serverBaseUrl);
    await prefs.setString('restaurantSlug', _remoteSettings.restaurantSlug);
    await prefs.setBool('wsEnabled', _remoteSettings.wsEnabled);
  }

  @override
  void dispose() {
    wsService.dispose();
    super.dispose();
  }
}
