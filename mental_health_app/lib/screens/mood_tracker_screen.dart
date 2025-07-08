import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mood_history_screen.dart';
import 'admin_analytics_screen.dart';
import 'user_profile_screen.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final _journalController = TextEditingController();
  final _notificationPlugin = FlutterLocalNotificationsPlugin();

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😡', 'label': 'Angry'},
    {'emoji': '😴', 'label': 'Tired'},
  ];

  String? _selectedMood;
  late Box _journalBox;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    await Hive.initFlutter();
    _journalBox = await Hive.openBox('journalBox');
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: androidSettings);
    await _notificationPlugin.initialize(settings);

    _scheduleDailyReminder();
  }

  Future<void> _scheduleDailyReminder() async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_mood_channel',
        'Daily Mood Check',
        channelDescription: 'Reminder for mood check-in',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final scheduledDate = _next8PM();

    await _notificationPlugin.zonedSchedule(
      0,
      'Mood Check-In',
      'Time for your daily mood update.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,        
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _next8PM() {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    return scheduled.isBefore(now) ? scheduled.add(const Duration(days: 1)) : scheduled;
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;

    final text = _journalController.text.trim();
    double polarity = 0.0;
    String sentiment = 'neutral';

    if (text.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.0.121:8000/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          polarity = (result['polarity'] as num).toDouble();
          sentiment = result['sentiment'];
        }
      } catch (e) {
        debugPrint("Sentiment API failed: $e");
      }
    }

    final entry = {
      'mood': _selectedMood,
      'timestamp': DateTime.now().toIso8601String(),
      'journal': text,
      'polarity': polarity,
      'sentiment': sentiment,
    };

    await _journalBox.add(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mood saved!")),
    );

    setState(() {
      _selectedMood = null;
      _journalController.clear();
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("🌈 Mood Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_outlined),
            tooltip: "Mood History",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: "Your Profile",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(today, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            Text("Select your mood:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: _moods.map((mood) {
                final isSelected = mood['emoji'] == _selectedMood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['emoji']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mood['emoji']!, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(mood['label']!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _journalController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Write how you feel today...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
              ),
              icon: const Icon(Icons.bar_chart),
              label: const Text("View Analytics"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saveMood,
              icon: const Icon(Icons.check),
              label: const Text("Save Mood"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
