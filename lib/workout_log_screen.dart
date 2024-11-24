
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  _WorkoutLogScreenState createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final TextEditingController exerciseController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

   Future<void> logWorkout() async {
    FirebaseFirestore.instance.collection('workouts').add({
      'exercise': exerciseController.text,
      'sets': int.parse(setsController.text),
      'reps': int.parse(repsController.text),
      'weight': double.parse(weightController.text),
      'date': DateTime.now(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Workout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: exerciseController,
              decoration: const InputDecoration(labelText: "Exercise"),
            ),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: "Sets"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: "Reps"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: logWorkout, child: const Text("Log Workout")),
          ],
        ),
      ),
    );
  }
}
