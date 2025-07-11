import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'mood_tracker_screen.dart';
import 'dart:convert';


class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('journalBox');
    final entries = box.values
      .where((e) =>
        e is Map &&
        e['mood'] != null &&
        e.containsKey('timestamp') &&
        e.containsKey('journal'))
      .toList()
      .reversed
      .toList();

    print("🧠 Loaded Entries: $entries"); // 🐞 debugging

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
                  final entry = entries[index] as Map;
                  final mood = entry['mood'];
                  final journal = entry['journal'] ?? '';
                  final timestamp = DateTime.parse(entry['timestamp']);
                  final formatted = DateFormat('EEE, MMM d, yyyy – h:mm a').format(timestamp);

                  final sentiment = entry['sentiment'] ?? 'unknown';
                  Map<String, dynamic> ai = {};
                  try {
                    final rawAi = entry['ai_analysis'];
                    if (rawAi is String && rawAi.isNotEmpty) {
                      ai = jsonDecode(rawAi); // ✅ safe to decode now
                    }
                  } catch (e) {
                    debugPrint("❌ AI analysis parsing failed: $e"); // 🐞 debugging
                  }                
                  final suggestion = ai['suggestion'] ?? '';
                  final followUp = ai['follow_up_question'] ?? '';
                  final estimatedTime = ai['estimated_time'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(mood, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(formatted, style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (journal.isNotEmpty)
                            Text('"$journal"',
                                style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 8),
                          Text("Sentiment: $sentiment",
                              style: TextStyle(color: Colors.teal.shade700)),
                          if (suggestion.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text("💡 Suggestion: $suggestion"),
                          ],
                          if (estimatedTime.isNotEmpty)
                            Text("⏱ Estimated Time: $estimatedTime"),
                          if (followUp.isNotEmpty)
                            Text("🤔 Follow-up: $followUp"),
                        ],
                      ),
                    ),
                  );
                },

              ),
      ),
    );
  }
}
