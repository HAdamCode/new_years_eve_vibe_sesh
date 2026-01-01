import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_wrapper.dart';
import 'core/auth/auth_service.dart';
import 'core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Amplify
  final authService = AuthService();
  await authService.configureAmplify();

  // Initialize deep link handling
  await deepLinkService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Study',
      debugShowCheckedModeBanner: false,
      navigatorKey: deepLinkService.navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}
