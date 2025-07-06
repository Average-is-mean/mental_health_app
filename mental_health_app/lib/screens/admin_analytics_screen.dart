import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  List<Map> entries = [];
  Map<String, int> moodCount = {};
  double averagePolarity = 0.0;

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  void loadEntries() {
    final box = Hive.box('journalBox');
    final allEntries = box.values.toList().cast<Map>();

    Map<String, int> moodMap = {};
    double totalPolarity = 0.0;
    int countWithPolarity = 0;

    for (var entry in allEntries) {
      if (entry['mood'] != null) {
        moodMap[entry['mood']] = (moodMap[entry['mood']] ?? 0) + 1;
      }

      if (entry['polarity'] != null) {
        totalPolarity += entry['polarity'];
        countWithPolarity++;
      }
    }

    setState(() {
      entries = allEntries;
      moodCount = moodMap;
      averagePolarity = countWithPolarity > 0 ? totalPolarity / countWithPolarity : 0.0;
    });
  }

  Widget buildChart() {
    if (entries.isEmpty) return const Text("No data to show");

    List<FlSpot> spots = [];
    List<String> dates = [];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry['timestamp'] == null || entry['polarity'] == null) continue;

      final timestamp = DateTime.parse(entry['timestamp']);
      final polarity = (entry['polarity'] ?? 0.0).toDouble();
      spots.add(FlSpot(i.toDouble(), polarity));
      dates.add(DateFormat('MMM d').format(timestamp));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: spots.length * 50,
        height: 300,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.teal,
                barWidth: 2,
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < dates.length) {
                      return Text(dates[index], style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            minY: -1,
            maxY: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Total Entries: ${entries.length}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Average Sentiment Polarity: ${averagePolarity.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text("Mood Distribution:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...moodCount.entries.map((e) => Text("${e.key}: ${e.value} entries")),
            const SizedBox(height: 20),
            const Text("Sentiment Over Time:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildChart(),
          ],
        ),
      ),
    );
  }
}
