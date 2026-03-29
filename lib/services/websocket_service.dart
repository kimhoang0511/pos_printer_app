import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../main.dart' show showToast;
import '../models/bill_model.dart';
import '../models/kitchen_ticket_model.dart';
import '../models/remote_settings.dart';
import 'app_state.dart';
import 'printer_service.dart' show PrintStatus;

enum WsStatus { disconnected, connecting, connected, reconnecting }

class WebSocketService extends ChangeNotifier {
  final AppState _appState;

  WsStatus _status = WsStatus.disconnected;
  RemoteSettings _settings = const RemoteSettings();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempt = 0;

  WsStatus get status => _status;

  String get statusLabel {
    switch (_status) {
      case WsStatus.connected:
        return 'Đã kết nối máy chủ';
      case WsStatus.connecting:
        return 'Đang kết nối máy chủ...';
      case WsStatus.reconnecting:
        return 'Đang kết nối lại...';
      case WsStatus.disconnected:
        return 'Chưa kết nối máy chủ';
    }
  }

  WebSocketService(this._appState);

  void configure(RemoteSettings settings) {
    _settings = settings;
    if (settings.wsEnabled && settings.isConfigured) {
      _disconnect();
      _connect();
    } else {
      _disconnect();
    }
  }

  void _connect() {
    _setStatus(WsStatus.connecting);
    try {
      final uri = Uri.parse(_settings.wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      // Consider connected after subscribing (handshake happens asynchronously)
      _setStatus(WsStatus.connected);
      _reconnectAttempt = 0;
      _startPingTimer();
    } catch (e) {
      _onError(e);
    }
  }

  void _disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _setStatus(WsStatus.disconnected);
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = map['event'] as String?;
      switch (event) {
        case 'print_bill':
          _handlePrintBill(
            map['data'] as Map<String, dynamic>,
            map['requestId'] as String?,
          );
        case 'print_kitchen':
          _handlePrintKitchen(
            map['data'] as Map<String, dynamic>,
            map['requestId'] as String?,
          );
        case 'pong':
          break;
        default:
          debugPrint('[WS] Unknown event: $event');
      }
    } catch (e) {
      debugPrint('[WS] Failed to parse message: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    if (_settings.wsEnabled && _settings.isConfigured) {
      _scheduleReconnect();
    } else {
      _setStatus(WsStatus.disconnected);
    }
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_settings.wsEnabled && _settings.isConfigured) {
      _scheduleReconnect();
    } else {
      _setStatus(WsStatus.disconnected);
    }
  }

  void _scheduleReconnect() {
    _setStatus(WsStatus.reconnecting);
    _reconnectAttempt++;
    final delay = _backoffDuration();
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt)');
    _reconnectTimer = Timer(delay, _connect);
  }

  Duration _backoffDuration() {
    final seconds = [1, 2, 4, 8, 30];
    final idx = (_reconnectAttempt - 1).clamp(0, seconds.length - 1);
    return Duration(seconds: seconds[idx]);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'ping'});
    });
  }

  void _handlePrintBill(Map<String, dynamic> data, String? requestId) {
    if (_appState.printStatus == PrintStatus.printing) {
      debugPrint('[WS] Busy printing, rejecting print_bill event');
      if (requestId != null) _sendAck(requestId, 'busy');
      return;
    }

    try {
      final bill = Bill.fromJson(data);
      final tableNumber = bill.tableNumber;
      showToast('🖨 Nhận lệnh in — Bàn $tableNumber');
      _appState.printBillFromRemote(bill).then((_) {
        if (requestId != null) _sendAck(requestId, 'printed');
      }).catchError((e) {
        showToast('Lỗi in bill bàn $tableNumber', isError: true);
        if (requestId != null) _sendAck(requestId, 'error');
      });
    } catch (e) {
      debugPrint('[WS] Failed to parse bill data: $e');
      if (requestId != null) _sendAck(requestId, 'error');
    }
  }

  void _handlePrintKitchen(Map<String, dynamic> data, String? requestId) {
    if (_appState.printStatus == PrintStatus.printing) {
      debugPrint('[WS] Busy printing, rejecting print_kitchen event');
      if (requestId != null) _sendAck(requestId, 'busy');
      return;
    }

    try {
      final ticket = KitchenTicket.fromJson(data);

      if (_isKitchenTicketExpired(ticket)) {
        debugPrint('[WS] Bỏ qua phiếu chế biến #${ticket.orderId} — quá 30 giây');
        if (requestId != null) _sendAck(requestId, 'printed');
        return;
      }

      showToast('🖨 In phiếu chế biến — Bàn ${ticket.tableNumber}');
      _appState.printKitchenTicketFromRemote(ticket).then((_) {
        if (requestId != null) _sendAck(requestId, 'printed');
      }).catchError((e) {
        showToast('Lỗi in phiếu chế biến bàn ${ticket.tableNumber}', isError: true);
        if (requestId != null) _sendAck(requestId, 'error');
      });
    } catch (e) {
      debugPrint('[WS] Failed to parse kitchen ticket data: $e');
      if (requestId != null) _sendAck(requestId, 'error');
    }
  }

  /// Trả về true nếu thời điểm yêu cầu in cách hiện tại > 30 giây.
  bool _isKitchenTicketExpired(KitchenTicket ticket) {
    final ref = ticket.requestedAt;
    if (ref == null) return false;
    return DateTime.now().difference(ref).abs().inSeconds > 60;
  }

  void _sendAck(String requestId, String status) {
    _send({'event': 'ack', 'requestId': requestId, 'status': status});
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[WS] Failed to send: $e');
    }
  }

  void _setStatus(WsStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}
