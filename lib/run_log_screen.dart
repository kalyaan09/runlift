import 'package:flutter/material.dart';

class RunLogScreen extends StatefulWidget {
  const RunLogScreen({super.key});

  @override
  _RunLogScreenState createState() => _RunLogScreenState();
}

class _RunLogScreenState extends State<RunLogScreen> {
  final TextEditingController distanceController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  void logRun() {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Run")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(labelText: "Distance (km)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Time taken"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: logRun, child: const Text("Log Run")),
          ],
        ),
      ),
    );
  }
}
