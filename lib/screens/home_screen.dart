import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/printer_settings.dart';
import '../services/printer_service.dart';
import '../models/remote_settings.dart';
import '../services/websocket_service.dart';
import '../widgets/bill_preview.dart';
import 'settings_screen.dart';
import 'edit_bill_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Hóa Đơn ESC/POS'),
        backgroundColor: const Color(0xFF6B3A2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Chỉnh sửa hóa đơn',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditBillScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return Column(
            children: [
              // WebSocket status strip
              ListenableBuilder(
                listenable: state.wsService,
                builder: (context, _) => _WsStatusStrip(
                  wsService: state.wsService,
                  remoteSettings: state.remoteSettings,
                ),
              ),

              // Print status banner
              if (state.printStatus != PrintStatus.idle)
                _StatusBanner(state: state),

              // Bill preview
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Card(
                        elevation: 4,
                        child: BillPreview(bill: state.bill),
                      ),
                    ),
                  ),
                ),
              ),

              // Printer info + buttons
              _BottomBar(state: state),
            ],
          );
        },
      ),
    );
  }
}

/// Dải trạng thái WebSocket phía trên màn hình
class _WsStatusStrip extends StatelessWidget {
  final WebSocketService wsService;
  final RemoteSettings remoteSettings;

  const _WsStatusStrip({
    required this.wsService,
    required this.remoteSettings,
  });

  @override
  Widget build(BuildContext context) {
    // Ẩn hoàn toàn nếu chưa cấu hình server
    if (!remoteSettings.isConfigured) return const SizedBox.shrink();

    // Lấy hostname ngắn gọn để hiển thị
    final serverHost = () {
      try {
        return Uri.parse(remoteSettings.serverBaseUrl).host;
      } catch (_) {
        return remoteSettings.serverBaseUrl;
      }
    }();

    // Trạng thái khi wsEnabled = false
    if (!remoteSettings.wsEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        color: Colors.grey.shade700,
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 12, color: Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Máy chủ: Đã tắt — $serverHost',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Text(
                'Bật',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final (color, isSpinning, dotChar, label) = switch (wsService.status) {
      WsStatus.connected => (
          Colors.green.shade700,
          false,
          '●',
          'Đã kết nối',
        ),
      WsStatus.connecting => (
          Colors.blue.shade700,
          true,
          '◌',
          'Đang kết nối...',
        ),
      WsStatus.reconnecting => (
          Colors.orange.shade700,
          true,
          '◌',
          'Đang kết nối lại...',
        ),
      WsStatus.disconnected => (
          Colors.red.shade700,
          false,
          '○',
          'Mất kết nối',
        ),
    };

    final showReconnect = wsService.status == WsStatus.disconnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      color: color,
      child: Row(
        children: [
          if (isSpinning)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 1.5,
              ),
            )
          else
            Text(
              dotChar,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label — $serverHost',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showReconnect)
            GestureDetector(
              onTap: () => context.read<AppState>().reconnectWs(),
              child: const Text(
                'Kết nối lại',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AppState state;

  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPrinting = state.printStatus == PrintStatus.printing;
    final isSuccess = state.printStatus == PrintStatus.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: isPrinting
          ? Colors.blue.shade700
          : isSuccess
              ? Colors.green.shade700
              : Colors.red.shade700,
      child: Row(
        children: [
          if (isPrinting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 18,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.statusMessage,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final AppState state;

  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final settings = state.settings;
    final isPrinting = state.printStatus == PrintStatus.printing;
    final isFetching = state.isFetchingFromApi;
    final isApiConfigured = state.remoteSettings.isConfigured;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Printer info
          Row(
            children: [
              const Icon(Icons.print, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  settings.connectionType == PrinterConnectionType.network
                      ? 'Mạng: ${settings.ipAddress}:${settings.port} — ${settings.paperWidth}mm'
                      : 'Bluetooth: ${settings.bluetoothName.isEmpty ? "Chưa chọn" : settings.bluetoothName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Buttons row
          Row(
            children: [
              // Fetch from API button (hiện khi đã cấu hình API)
              if (isApiConfigured) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: (isPrinting || isFetching)
                        ? null
                        : () => context.read<AppState>().fetchAndPrint(),
                    icon: isFetching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download, size: 18),
                    label: Text(
                      isFetching ? 'Đang lấy...' : 'Lấy lệnh in',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B3A2A),
                      side: const BorderSide(color: Color(0xFF6B3A2A)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Print button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: (isPrinting || isFetching)
                      ? null
                      : () => context.read<AppState>().printBill(),
                  icon: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text(isPrinting ? 'Đang in...' : 'IN HÓA ĐƠN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B3A2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
