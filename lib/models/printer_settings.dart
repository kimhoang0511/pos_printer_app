enum PrinterConnectionType { network, bluetooth }

class PrinterSettings {
  final PrinterConnectionType connectionType;
  // Network — Máy in bếp (Kitchen Ticket)
  final String ipAddress;
  final int port;
  // Network — Máy in lễ tân (Bill Ticket)
  final String billIpAddress;
  final int billPort;
  // Bluetooth
  final String bluetoothAddress;
  final String bluetoothName;
  // Paper
  final int paperWidth; // 58 or 80 mm
  // Encoding
  final bool unicodeVietnamese; // true = máy in hỗ trợ UTF-8/Unicode tiếng Việt

  PrinterSettings({
    this.connectionType = PrinterConnectionType.network,
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
    this.billIpAddress = '192.168.1.101',
    this.billPort = 9100,
    this.bluetoothAddress = '',
    this.bluetoothName = '',
    this.paperWidth = 80,
    this.unicodeVietnamese = false,
  });

  PrinterSettings copyWith({
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? billIpAddress,
    int? billPort,
    String? bluetoothAddress,
    String? bluetoothName,
    int? paperWidth,
    bool? unicodeVietnamese,
  }) {
    return PrinterSettings(
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      billIpAddress: billIpAddress ?? this.billIpAddress,
      billPort: billPort ?? this.billPort,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      bluetoothName: bluetoothName ?? this.bluetoothName,
      paperWidth: paperWidth ?? this.paperWidth,
      unicodeVietnamese: unicodeVietnamese ?? this.unicodeVietnamese,
    );
  }
}
