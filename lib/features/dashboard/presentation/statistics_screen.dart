import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../assessment/data/assessment_result_repository.dart';
import '../../assessment/models/assessment_result.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(assessmentResultRepoProvider);
    final history = repo.getHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultata dine', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'Ingen resultat enno! Ta ei kartlegging først.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : _buildDashboard(context, history),
    );
  }

  Widget _buildDashboard(BuildContext context, List<AssessmentResult> history) {
    history.sort((a, b) => a.date.compareTo(b.date));

    final Map<String, List<int>> categoryStats = {};
    for (var res in history) {
      res.categoryResults.forEach((cat, isCorrect) {
        if (!categoryStats.containsKey(cat)) {
          categoryStats[cat] = [0, 0];
        }
        categoryStats[cat]![0] += isCorrect ? 1 : 0;
        categoryStats[cat]![1] += 1;
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Utvikling (Mestring %)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLineChartCard(history),
          const SizedBox(height: 32),
          const Text(
            'Svake og sterke sidene dine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._buildCategoryBars(categoryStats),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(List<AssessmentResult> history) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
        final pct = history[i].total > 0 ? (history[i].score / history[i].total) * 100 : 0.0;
        spots.add(FlSpot(i.toDouble(), pct));
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        height: 250,
        padding: const EdgeInsets.only(right: 24, top: 24, bottom: 16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.deepPurple,
                barWidth: 5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.deepPurple.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryBars(Map<String, List<int>> stats) {
    return stats.entries.map((entry) {
      final name = entry.key;
      final correct = entry.value[0];
      final total = entry.value[1];
      final pct = total > 0 ? (correct / total) : 0.0;

      final readableName = _formatCategoryName(name);
      
      Color barColor = Colors.orange;
      if (pct >= 0.8) barColor = Colors.green;
      else if (pct >= 0.5) barColor = Colors.teal;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(readableName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${(pct * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: barColor)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                color: barColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatCategoryName(String key) {
    switch (key) {
      case 'substantiv_kjonn': return 'Substantiv (Kjønn)';
      case 'substantiv_boying': return 'Substantiv (Bøying)';
      case 'verb_boying': return 'Verb';
      case 'ordforrad': return 'Ordforråd';
      case 'pronomen': return 'Pronomen';
      case 'eiendomsord': return 'Eiendomsord (Plassering)';
      default: return key;
    }
  }
}
