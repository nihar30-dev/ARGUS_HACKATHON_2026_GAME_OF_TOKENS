import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meeting_repository.dart';
import '../theme/app_theme.dart';
import 'routes.dart';

class MeetWiseApp extends StatelessWidget {
  const MeetWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<MeetingRepository>(
      create: (_) => MeetingRepository(),
      child: MaterialApp(
        title: 'MeetWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: Routes.home,
        onGenerateRoute: Routes.onGenerateRoute,
        // Catch unhandled widget-layer errors without showing the red crash screen.
        builder: (context, child) {
          ErrorWidget.builder = (details) => AppErrorBoundary(errorDetails: details);
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
