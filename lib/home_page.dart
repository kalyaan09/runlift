import 'package:flutter/material.dart';
import 'workout_log_screen.dart';
import 'run_log_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Log Workout"),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const WorkoutLogScreen()));
              },
            ),
            ElevatedButton(
              child: const Text("Log Run"),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const RunLogScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
