import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/printer_settings.dart';
import '../models/remote_settings.dart';
import '../services/app_state.dart';
import '../services/printer_scanner.dart';
import '../services/websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Printer settings
  late PrinterConnectionType _connectionType;
  late TextEditingController _ipCtrl;
  late TextEditingController _portCtrl;
  late int _paperWidth;

  // Remote settings
  late TextEditingController _serverBaseUrlCtrl;
  late TextEditingController _slugCtrl;
  late bool _wsEnabled;

  // Scanner state
  bool _scanning = false;
  int _scanProgress = 0;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _connectionType = s.connectionType;
    _ipCtrl = TextEditingController(text: s.ipAddress);
    _portCtrl = TextEditingController(text: s.port.toString());
    _paperWidth = s.paperWidth;

    final r = context.read<AppState>().remoteSettings;
    _serverBaseUrlCtrl = TextEditingController(text: r.serverBaseUrl);
    _slugCtrl = TextEditingController(text: r.restaurantSlug);
    _wsEnabled = r.wsEnabled;
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _serverBaseUrlCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _scanProgress = 0;
      _scanResults = [];
    });
    try {
      final results = await PrinterScanner.scan(
        port: int.tryParse(_portCtrl.text) ?? 9100,
        onProgress: (scanned, total) {
          if (mounted) setState(() => _scanProgress = scanned);
        },
      );
      if (mounted) setState(() => _scanResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi quét mạng: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _save() {
    context.read<AppState>().updateSettings(
          PrinterSettings(
            connectionType: _connectionType,
            ipAddress: _ipCtrl.text.trim(),
            port: int.tryParse(_portCtrl.text) ?? 9100,
            paperWidth: _paperWidth,
          ),
        );
    context.read<AppState>().updateRemoteSettings(
          RemoteSettings(
            serverBaseUrl: _serverBaseUrlCtrl.text.trim(),
            restaurantSlug: _slugCtrl.text.trim(),
            wsEnabled: _wsEnabled,
          ),
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: const Color(0xFF6B3A2A),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('LƯU', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Loại kết nối ───────────────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Loại kết nối máy in',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<PrinterConnectionType>(
                  value: PrinterConnectionType.network,
                  groupValue: _connectionType,
                  title: const Text('Mạng (TCP/IP)'),
                  subtitle: const Text('Wi-Fi / LAN — hoạt động mọi nền tảng'),
                  onChanged: (v) => setState(() => _connectionType = v!),
                ),
                RadioListTile<PrinterConnectionType>(
                  value: PrinterConnectionType.bluetooth,
                  groupValue: _connectionType,
                  title: const Text('Bluetooth'),
                  subtitle: const Text('Android / iOS'),
                  onChanged: (v) => setState(() => _connectionType = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Network settings ───────────────────────────────────
          if (_connectionType == PrinterConnectionType.network)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt mạng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ IP máy in',
                        hintText: '192.168.1.100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.router),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Port (mặc định: 9100)',
                        hintText: '9100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    // Nút quét mạng LAN
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _scanning ? null : _startScan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find, size: 18),
                        label: Text(
                          _scanning
                              ? 'Đang quét... ($_scanProgress/254)'
                              : 'Dò tìm máy in trong mạng LAN',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B3A2A),
                          side: const BorderSide(color: Color(0xFF6B3A2A)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    // Progress bar khi đang quét
                    if (_scanning) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _scanProgress / 254,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF6B3A2A),
                      ),
                    ],
                    // Kết quả quét
                    if (!_scanning && _scanResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Máy in tìm thấy — nhấn để chọn:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      ...(_scanResults.map((r) => InkWell(
                            onTap: () {
                              setState(() => _ipCtrl.text = r.ip);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã chọn ${r.ip}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.green.shade50,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.print,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.ip,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'port ${r.port}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 12, color: Colors.grey),
                                ],
                              ),
                            ),
                          ))),
                    ],
                    if (!_scanning && _scanResults.isEmpty && _scanProgress == 254) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Không tìm thấy máy in nào trong mạng LAN.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Hướng dẫn: Vào cài đặt mạng máy in để xem IP.\n'
                      'Port mặc định của hầu hết máy in ESC/POS là 9100.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bluetooth placeholder ──────────────────────────────
          if (_connectionType == PrinterConnectionType.bluetooth)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tính năng Bluetooth yêu cầu cấp quyền trên thiết bị.\n'
                      'Sử dụng kết nối mạng (TCP/IP) để tương thích tốt nhất.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Tìm kiếm thiết bị'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tính năng Bluetooth đang được phát triển.\n'
                              'Vui lòng dùng kết nối mạng.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Khổ giấy ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khổ giấy mặc định',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Server có thể ghi đè khi gửi lệnh in',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 mm')),
                      ButtonSegment(value: 80, label: Text('80 mm')),
                    ],
                    selected: {_paperWidth},
                    onSelectionChanged: (v) =>
                        setState(() => _paperWidth = v.first),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Kết nối máy chủ từ xa ──────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết nối máy chủ từ xa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhận lệnh in tự động qua WebSocket',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  // Status indicator
                  ListenableBuilder(
                    listenable: context.read<AppState>().wsService,
                    builder: (context, _) {
                      final ws = context.read<AppState>().wsService;
                      return _WsStatusRow(status: ws.status, enabled: _wsEnabled);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Enable toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nhận lệnh in từ xa'),
                    subtitle: const Text('Kết nối WebSocket khi khởi động'),
                    value: _wsEnabled,
                    onChanged: (v) => setState(() => _wsEnabled = v),
                  ),

                  const SizedBox(height: 8),

                  // Server base URL
                  TextField(
                    controller: _serverBaseUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ máy chủ',
                      hintText: 'https://api.example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud),
                    ),
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 12),

                  // Restaurant slug
                  TextField(
                    controller: _slugCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mã kết nối',
                      hintText: '••••••••',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                      helperText: 'Xem trong phần cài đặt web app',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B3A2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('LƯU CÀI ĐẶT',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _WsStatusRow extends StatelessWidget {
  final WsStatus status;
  final bool enabled;

  const _WsStatusRow({required this.status, required this.enabled});

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const Row(
        children: [
          Icon(Icons.circle, size: 10, color: Colors.grey),
          SizedBox(width: 6),
          Text('Đã tắt', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    final (icon, color, label) = switch (status) {
      WsStatus.connected => (Icons.circle, Colors.green, 'Đã kết nối'),
      WsStatus.connecting => (Icons.circle, Colors.blue, 'Đang kết nối...'),
      WsStatus.reconnecting => (Icons.circle, Colors.orange, 'Đang kết nối lại...'),
      WsStatus.disconnected => (Icons.circle, Colors.grey, 'Chưa kết nối'),
    };

    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
