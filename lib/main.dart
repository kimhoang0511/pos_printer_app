import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showToast(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable(); // Giữ màn hình luôn sáng
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Xử lý deep link khi app đang chạy (foreground/background)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // pos-printer://print → trigger fetchAndPrint
    if (uri.scheme == 'pos-printer' && uri.host == 'print') {
      context.read<AppState>().fetchAndPrint();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In Hóa Đơn ESC/POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3A2A),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 2,
        ),
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const HomeScreen(),
    );
  }
}
