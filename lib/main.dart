import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'providers/portfolio_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  await NotificationService.requestPermissions();
  await BackgroundService().ensureScheduled();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PortfolioProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
          surface: Color(0xFF111111),
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Color(0xFF1E1E1E),
          onSecondary: Colors.white,
          surfaceVariant: Color(0xFF1A1A1A),
          onSurfaceVariant: Color(0xFFAAAAAA),
          primaryContainer: Color(0xFF1E1E1E),
          onPrimaryContainer: Colors.white,
          secondaryContainer: Color(0xFF1A1A1A),
          onSecondaryContainer: Color(0xFFCCCCCC),
          outline: Color(0xFF2A2A2A),
          outlineVariant: Color(0xFF222222),
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const DashboardScreen(),
    );
  }
}
