import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'journal_history_screen.dart';



class _JournalScreenState extends State<JournalScreen> {
  late final TextEditingController _controller;
  String? _sentiment;
  double? _polarity;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(); // ✅ Initialize controller
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ Dispose properly
    super.dispose();
  }

  Future<void> analyzeSentiment() async {
    setState(() => _loading = true);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': _controller.text}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        _sentiment = result['sentiment'];
        _polarity = result['polarity'];
        _loading = false;
      });

      final box = Hive.box('journalBox');
      final now = DateTime.now();
      await box.add({
        'text': _controller.text,
        'sentiment': result['sentiment'],
        'polarity': result['polarity'],
        'timestamp': now.toIso8601String(),
      });
    } else {
      setState(() {
        _sentiment = 'Error';
        _polarity = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const JournalHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Write how you feel today...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : analyzeSentiment,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Analyze"),
            ),
            const SizedBox(height: 24),
            if (_sentiment != null && _polarity != null)
              Column(
                children: [
                  Text(
                    "Sentiment: $_sentiment",
                    style: TextStyle(
                      fontSize: 22,
                      color: _sentiment == "positive"
                          ? Colors.green
                          : _sentiment == "negative"
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Polarity Score: ${_polarity!.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
