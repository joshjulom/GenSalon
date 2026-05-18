import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/root_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadAll(),
      child: const GenSalonApp(),
    ),
  );
}

class GenSalonApp extends StatelessWidget {
  const GenSalonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenSalon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const RootShell(),
    );
  }
}
