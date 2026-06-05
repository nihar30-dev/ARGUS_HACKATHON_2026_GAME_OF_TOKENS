import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/meeting_input_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MeetWiseApp());
}

class MeetWiseApp extends StatelessWidget {
  const MeetWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ApiService>(
      create: (_) => ApiService(),
      child: MaterialApp(
        title: 'MeetWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const MeetingInputScreen(),
      ),
    );
  }
}
