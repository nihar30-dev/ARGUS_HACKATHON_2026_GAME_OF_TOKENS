import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meeting_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'routes.dart';

class MeetWiseApp extends StatelessWidget {
  const MeetWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider<MeetingRepository>(create: (_) => MeetingRepository()),
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
