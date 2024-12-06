import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      // Fetch workouts
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .get();

      // Fetch runs
      final runSnapshot = await FirebaseFirestore.instance
          .collection('runs')
          .where('userId', isEqualTo: userId)
          .get();

      // Combine results from both collections
      final history = [
        ...workoutSnapshot.docs.map((doc) => {
              'type': 'Workout',
              ...doc.data(),
            }),
        ...runSnapshot.docs.map((doc) => {
              'type': 'Run',
              ...doc.data(),
            }),
      ];

      // Sort by date in descending order
      history.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

      return history;
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No history available."));
          }

          final history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];

              if (entry['type'] == 'Workout') {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Workout on: ${(entry['date'] as Timestamp).toDate().toString()}"),
                        // Check if 'exercises' exists and is a list
                        if (entry['exercises'] != null && entry['exercises'] is List)
                          for (var exercise in entry['exercises'])
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Exercise: ${exercise['name'] ?? 'Unknown'}"),
                                  if (exercise['sets'] != null && exercise['sets'] is List)
                                    for (var set in exercise['sets'])
                                      Row(
                                        children: [
                                          Text("Reps: ${set['reps'] ?? 'N/A'}"),
                                          const SizedBox(width: 10),
                                          Text("Weight: ${set['weight'] ?? 'N/A'} kg"),
                                        ],
                                      ),
                                ],
                              ),
                            )
                        else
                          const Text("No exercises recorded."),
                      ],
                    ),
                  ),
                );
              } else if (entry['type'] == 'Run') {
                return ListTile(
                  title: Text("Run: ${entry['distance'] ?? 'Unknown'} km"),
                  subtitle: Text("Time: ${entry['time'] ?? 'N/A'}"),
                  trailing: Text((entry['date'] as Timestamp).toDate().toString()),
                );
              } else {
                return const SizedBox.shrink(); // Handle unexpected types
              }
            },
          );
        },
      ),
    );
  }
}
