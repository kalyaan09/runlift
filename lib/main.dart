import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RunLiftApp());
}

class RunLiftApp extends StatelessWidget {
  const RunLiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunLift',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
