import 'package:flutter/material.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalStatsWidget extends StatelessWidget {
  final GoalStatistics statistics;
  const GoalStatsWidget({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('目標の統計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('合計', statistics.totalGoals.toString()),
                _buildStat('完了', statistics.completedGoals.toString()),
                _buildStat('アクティブ', statistics.activeGoals.toString()),
                _buildStat('一時停止', statistics.pausedGoals.toString()),
                _buildStat('キャンセル', statistics.cancelledGoals.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('完了率', '${(statistics.safeCompletionRate * 100).toStringAsFixed(1)}%'),
                _buildStat('期限切れ', statistics.overdueGoals.toString()),
                _buildStat('平均進捗', '${(statistics.safeAverageProgress * 100).toStringAsFixed(1)}%'),
                _buildStat('マイルストーン完了率', '${(statistics.safeMilestoneCompletionRate * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    // NaNや無限大の値を安全に処理
    String safeValue = value;
    if (value.contains('NaN') || value.contains('Infinity')) {
      safeValue = '0.0';
    }
    
    return Column(
      children: [
        Text(safeValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
} 