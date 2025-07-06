import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'mood_tracker_screen.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('journalBox');
    final entries = box.values.toList().reversed.toList();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mood History"),
          leading: IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Go to Home",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
              );
            },
          ),
        ),
        body: entries.isEmpty
            ? const Center(child: Text("No moods recorded yet."))
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final mood = entry['mood'];
                  final journal = entry['journal'] ?? '';
                  final timestamp = DateTime.parse(entry['timestamp']);
                  final formatted = DateFormat('EEE, MMM d, yyyy – h:mm a').format(timestamp);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Text(
                        mood,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(formatted),
                      subtitle: journal.isNotEmpty
                        ? Text(
                            '"$journal"',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            )
                        : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
