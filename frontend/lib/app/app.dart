import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/meeting_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'routes.dart';

class MeetWiseApp extends StatelessWidget {
  final AuthService authService;

  const MeetWiseApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ProxyProvider<AuthService, MeetingRepository>(
          update: (_, auth, prev) => prev ?? MeetingRepository(authService: auth),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, notifier, _) => MaterialApp(
          title: 'MeetWise',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: notifier.mode,
          initialRoute: Routes.home,
          onGenerateRoute: Routes.onGenerateRoute,
          builder: (context, child) {
            ErrorWidget.builder =
                (details) => AppErrorBoundary(errorDetails: details);
            return child ?? const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
