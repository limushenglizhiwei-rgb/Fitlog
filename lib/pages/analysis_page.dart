import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';

import 'analysis_detail_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  static const Color _black = Color(0xFF171B26);
  static const Color _secondary = Color(0xFF8A8F98);
  static const Color _blue = Color(0xFF2588EE);
  static const Color _divider = Color(0xFFECEEF1);

  bool _isLoading = true;
  String? _error;

  double _totalVolume = 0;
  double _completion = 0;
  double? _squatPR;
  double? _benchPR;

  List<Map<String, dynamic>> _recentWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final today = _dateOnly(DateTime.now());
      final startDate = today.subtract(const Duration(days: 29));

      // 1. 读取每日训练趋势
      final dailyStats = await DatabaseHelper.getDailyWorkoutStats(
        startDate: startDate,
        endDate: today,
      );

      double volume = 0;
      for (final stats in dailyStats.values) {
        volume += stats['volume'] ?? 0;
      }

      // 2. 读取训练记录，计算整体完成度
      final workouts = await DatabaseHelper.getWorkoutTrend(
        startDate: startDate,
      );

      int totalSets = 0;
      int completedSets = 0;

      for (final workout in workouts) {
        totalSets += (workout['total_sets'] as num?)?.toInt() ?? 0;
        completedSets += (workout['completed_sets'] as num?)?.toInt() ?? 0;
      }

      final completion = totalSets > 0 ? completedSets * 100 / totalSets : 0.0;

      // 3. 读取动作 PR
      final db = await DatabaseHelper.database;

      final prRows = await db.rawQuery('''
        SELECT
          we.name AS exercise_name,
          MAX(ws.actual_weight) AS max_weight
        FROM workout_exercises we
        JOIN workout_sets ws ON ws.exercise_id = we.id
        JOIN workouts w ON w.id = we.workout_id
        WHERE ws.is_completed = 1
          AND ws.actual_weight IS NOT NULL
          AND ws.actual_weight > 0
        GROUP BY we.name
      ''');

      double? squatPR;
      double? benchPR;

      for (final row in prRows) {
        final name = row['exercise_name']?.toString() ?? '';
        final weight = (row['max_weight'] as num?)?.toDouble();

        if (weight == null) continue;

        if (name.contains('深蹲')) {
          if (squatPR == null || weight > squatPR) {
            squatPR = weight;
          }
        }

        if (name.contains('卧推')) {
          if (benchPR == null || weight > benchPR) {
            benchPR = weight;
          }
        }
      }

      // 4. 读取最近训练记录
      final recent = await DatabaseHelper.getRecentWorkouts(limit: 4);

      setState(() {
        _totalVolume = volume;
        _completion = completion;
        _squatPR = squatPR;
        _benchPR = benchPR;
        _recentWorkouts = recent;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('训练分析加载失败：$e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = '数据加载失败，请稍后重试';
      });
    }
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _formatWeight(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '训练分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _black,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadAnalysis,
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAINING OVERVIEW · 近30天',
            style: TextStyle(fontSize: 13, color: _secondary),
          ),

          const SizedBox(height: 28),

          // 训练趋势
          _buildClickableSectionHeader(
            title: '训练趋势',
            subtitle: '训练量与完成度变化',
            onTap: _openTrendSheet,
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildMetric(_formatNumber(_totalVolume), '累计训练量 · kg'),
              ),
              Expanded(
                child: _buildMetric(
                  '${_completion.toStringAsFixed(0)}%',
                  '计划完成度',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          _buildDivider(),

          // 训练表现
          const SizedBox(height: 28),
          _buildClickableSectionHeader(
            title: '训练表现',
            subtitle: 'PR 与动作进步',
            onTap: () => _openDetail('训练表现'),
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(child: _buildMetric(_formatWeight(_squatPR), '深蹲 PR')),
              Expanded(child: _buildMetric(_formatWeight(_benchPR), '卧推 PR')),
            ],
          ),

          const SizedBox(height: 28),
          _buildDivider(),

          // 单次训练分析
          const SizedBox(height: 28),
          _buildSectionHeader('单次训练分析', '选择某一次训练，查看详细执行情况'),
          const SizedBox(height: 18),

          if (_recentWorkouts.isEmpty)
            const Text(
              '暂无训练记录',
              style: TextStyle(fontSize: 13, color: _secondary),
            )
          else ...[
            _buildRecentWorkoutItem(_recentWorkouts.first),
            const SizedBox(height: 12),
            _buildTextLink('全部训练记录', onTap: () => _openDetail('训练记录')),
          ],
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutItem(Map<String, dynamic> workout) {
    final id = (workout['id'] as num).toInt();
    final completed = (workout['completed_sets'] as num?)?.toInt() ?? 0;
    final total = (workout['total_sets'] as num?)?.toInt() ?? 0;
    final name = workout['plan_name']?.toString() ?? '训练记录';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkoutDetailPage(workoutId: id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(() {
                      final date = DateTime.tryParse(workout['completed_at']?.toString() ?? '');

                      if (date == null) return '未知日期';

                      return '${date.year}.'
                          '${date.month.toString().padLeft(2, '0')}.'
                          '${date.day.toString().padLeft(2, '0')}';
                    })()}  ·  完成 $completed / $total 组',
                    style: const TextStyle(fontSize: 12, color: _secondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 26, color: _secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: _secondary)),
      ],
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: _black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(fontSize: 12, color: _secondary)),
      ],
    );
  }

  Widget _buildClickableSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _buildSectionHeader(title, subtitle)),
          const Text(
            '查看详情',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: _divider);
  }

  Widget _buildTextLink(String title, {required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _blue,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward, size: 15, color: _blue),
        ],
      ),
    );
  }

  // 训练趋势：底部弹窗
  void _openTrendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TrendSheet(),
    );
  }

  void _openDetail(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisDetailPage(title: title)),
    );
  }
}

// --------------------------------------------------
// 训练趋势底部弹窗
// --------------------------------------------------

class _TrendSheet extends StatefulWidget {
  const _TrendSheet();

  @override
  State<_TrendSheet> createState() => _TrendSheetState();
}

class _TrendSheetState extends State<_TrendSheet> {
  static const Color _black = Color(0xFF171B26);
  static const Color _blue = Color(0xFF2588EE);
  static const Color _secondary = Color(0xFF8A8F98);

  int _days = 30;
  bool _loading = true;
  double _volume = 0;
  double _completion = 0;
  Map<String, Map<String, double>> _dailyStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final today = DateTime.now();
      final end = DateTime(today.year, today.month, today.day);
      final start = end.subtract(Duration(days: _days - 1));

      final stats = await DatabaseHelper.getDailyWorkoutStats(
        startDate: start,
        endDate: end,
      );

      final workouts = await DatabaseHelper.getWorkoutTrend(startDate: start);

      double volume = 0;
      for (final item in stats.values) {
        volume += item['volume'] ?? 0;
      }

      int totalSets = 0;
      int completedSets = 0;

      for (final workout in workouts) {
        totalSets += (workout['total_sets'] as num?)?.toInt() ?? 0;
        completedSets += (workout['completed_sets'] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _dailyStats = stats;
        _volume = volume;
        _completion = totalSets > 0 ? completedSets * 100 / totalSets : 0;
        _loading = false;
      });
    } catch (e) {
      debugPrint('趋势详情加载失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '训练趋势',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _black,
              ),
            ),
            const SizedBox(height: 18),

            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('近7天')),
                ButtonSegment(value: 30, label: Text('近30天')),
              ],
              selected: {_days},
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color.fromARGB(226, 8, 126, 252); // 选中背景
                  }
                  return const Color.fromARGB(255, 250, 251, 252); // 未选中背景
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white; // 选中文字
                  }
                  return _secondary; // 未选中文字
                }),
                side: WidgetStateProperty.all(
                  BorderSide.none, // 去掉边框
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              onSelectionChanged: (value) {
                setState(() => _days = value.first);
                _loadData();
              },
            ),

            const SizedBox(height: 26),

            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _summary(
                      '累计训练量',
                      '${_volume.toStringAsFixed(0)} kg',
                    ),
                  ),
                  Expanded(
                    child: _summary(
                      '计划完成度',
                      '${_completion.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                '每日训练量',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _black,
                ),
              ),
              const SizedBox(height: 14),

              Expanded(child: _buildDailyList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _secondary)),
      ],
    );
  }

  Widget _buildDailyList() {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(Duration(days: _days - 1));

    final dates = List.generate(
      _days,
      (index) => start.add(Duration(days: index)),
    );

    final values = dates.map((date) {
      final key =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      return _dailyStats[key]?['volume'] ?? 0;
    }).toList();

    final maxVolume = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    if (maxVolume == 0) {
      return const Center(
        child: Text(
          '这个时间段还没有训练数据',
          style: TextStyle(color: _secondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final value = values[index];
        final ratio = value / maxVolume;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 12, color: _secondary),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF0F2F5),
                    color: _blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  value == 0 ? '--' : value.toStringAsFixed(0),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: _black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
