class RemoteSettings {
  /// Base URL của server, ví dụ: https://api.example.com
  /// WS URL tự động được derive: wss://api.example.com/ws/printer?slug=...
  final String serverBaseUrl;
  final String restaurantSlug;
  final bool wsEnabled;

  const RemoteSettings({
    this.serverBaseUrl = 'https://api.kinzo.vn',
    this.restaurantSlug = '',
    this.wsEnabled = false,
  });

  RemoteSettings copyWith({
    String? serverBaseUrl,
    String? restaurantSlug,
    bool? wsEnabled,
  }) {
    return RemoteSettings(
      serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
      restaurantSlug: restaurantSlug ?? this.restaurantSlug,
      wsEnabled: wsEnabled ?? this.wsEnabled,
    );
  }

  bool get isConfigured =>
      serverBaseUrl.isNotEmpty && restaurantSlug.isNotEmpty;

  /// wss://api.example.com/ws/printer?slug=my-restaurant
  String get wsUrl {
    if (!isConfigured) return '';
    final base = serverBaseUrl
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://')
        .replaceFirst(RegExp(r'/$'), '');
    return '$base/ws/printer?slug=$restaurantSlug';
  }

  /// https://api.example.com/api/printer/pending?slug=my-restaurant
  String get pendingUrl {
    if (!isConfigured) return '';
    final base = serverBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return '$base/api/printer/pending?slug=$restaurantSlug';
  }

  /// https://api.example.com/api/printer/ack/{requestId}?slug=my-restaurant
  String ackUrl(String requestId) {
    final base = serverBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return '$base/api/printer/ack/$requestId?slug=$restaurantSlug';
  }
}
