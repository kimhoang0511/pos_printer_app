enum PrinterConnectionType { network, bluetooth }

class PrinterSettings {
  final PrinterConnectionType connectionType;
  // Network
  final String ipAddress;
  final int port;
  // Bluetooth
  final String bluetoothAddress;
  final String bluetoothName;
  // Paper
  final int paperWidth; // 58 or 80 mm

  PrinterSettings({
    this.connectionType = PrinterConnectionType.network,
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
    this.bluetoothAddress = '',
    this.bluetoothName = '',
    this.paperWidth = 80,
  });

  PrinterSettings copyWith({
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? bluetoothAddress,
    String? bluetoothName,
    int? paperWidth,
  }) {
    return PrinterSettings(
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      bluetoothName: bluetoothName ?? this.bluetoothName,
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }
}
