import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  runApp(MeetWiseApp(authService: authService));
}
