import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_log_screen.dart';
import 'run_log_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<Map<String, dynamic>>> fetchRecentLogs() async {
    final workoutSnapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    final workoutLogs = workoutSnapshot.docs.map((doc) {
      final data = doc.data();
      data['type'] = 'workout';
      return data;
    }).toList();
    final runSnapshot = await FirebaseFirestore.instance
        .collection('runs')
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    final runLogs = runSnapshot.docs.map((doc) {
      final data = doc.data();
      data['type'] = 'run';
      return data;
    }).toList();
    final combinedLogs = [...workoutLogs, ...runLogs];
    combinedLogs.sort((a, b) =>
        (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

    return combinedLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchRecentLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No recent workouts/runs found."));
                  }

                  final logs = snapshot.data!;
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isWorkout = log['type'] == 'workout';
                      return ListTile(
                        title: Text(isWorkout
                            ? 'Workout: ${log['exercise']}'
                            : 'Run: ${log['distance']} km'),
                        subtitle: Text(isWorkout
                            ? 'Sets: ${log['sets']}, Reps: ${log['reps']}, Weight: ${log['weight']} kg'
                            : 'Time: ${log['time']}'),
                        trailing: Text(
                            '${(log['date'] as Timestamp).toDate().toLocal()}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
