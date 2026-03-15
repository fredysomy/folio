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
        brightness: Brightness.light,
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
