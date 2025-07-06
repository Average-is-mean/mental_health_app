import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  _JournalHistoryScreenState createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  bool showChart = false;

  Widget buildLineChart(List<Map> entries) {
  if (entries.isEmpty) {
    return const Center(child: Text("No data available"));
  }

  // Group entries by date and calculate average polarity per day
  final Map<String, List<double>> groupedByDate = {};
  for (var entry in entries) {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['timestamp']));
    final polarity = (entry['polarity'] ?? 0.0).toDouble();

    if (!groupedByDate.containsKey(date)) {
      groupedByDate[date] = [];
    }
    groupedByDate[date]!.add(polarity);
  }

  // Create chart points from averaged daily values
  final sortedDates = groupedByDate.keys.toList()..sort();
  final List<FlSpot> spots = [];
  final List<String> dates = [];

  for (int i = 0; i < sortedDates.length; i++) {
    final date = sortedDates[i];
    final avgPolarity = groupedByDate[date]!.reduce((a, b) => a + b) / groupedByDate[date]!.length;
    spots.add(FlSpot(i.toDouble(), avgPolarity));
    dates.add(DateFormat('MMM d').format(DateTime.parse(date)));
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
              barWidth: 2,
              color: Colors.teal,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
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
    final box = Hive.box('journalBox');
    print("All entries: ${box.values.toList()}");
    final entries = box.values.toList().cast<Map>().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal History'),
        actions: [
          IconButton(
            icon: Icon(showChart ? Icons.list : Icons.show_chart),
            onPressed: () {
              setState(() {
                showChart = !showChart;
              });
            },
          ),
        ],
      ),
      body: showChart
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: buildLineChart(entries),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final timestamp = DateTime.parse(entry['timestamp']);
                final formattedDate = DateFormat('EEE, MMM d yyyy – hh:mm a').format(timestamp);

                return ListTile(
                  title: Text(entry['text'] ?? ''),
                  subtitle: Text(
                    'Sentiment: ${entry['sentiment']} (Polarity: ${entry['polarity'].toStringAsFixed(2)})\n$formattedDate',
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
