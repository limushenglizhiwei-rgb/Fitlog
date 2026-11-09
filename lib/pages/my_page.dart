import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';

import 'training_calendar_page.dart';

import 'package:flutter_application_1/pages/weight_trend_page.dart';
import 'package:flutter_application_1/pages/analysis_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  static const Color _blue = Color(0xFF2588EE);
  static const Color _black = Color(0xFF171B26);
  static const Color _grey = Color(0xFFF5F5F5);
  static const Color _secondary = Color(0xFF8A8F98);

  String selectedMetric = '完成度';

  List<DateTime> _chartDates = [];
  List<double?> _completionData = [];

  bool _isChartLoading = true;

  String? _chartError;
  int _overviewWorkoutCount = 0;
  double _overviewCompletion = 0;
  bool _isOverviewLoading = true;
  int? _selectedChartIndex;

  double get _chartAverage {
    final values = _completionData.whereType<double>().toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  void _openTrainingAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisPage()),
    );
  }

  void _openTrainingCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingCalendarPage()),
    );
  }

  void _openBodyMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeightTrendPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _loadOverviewData();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}';

  Future<void> _loadChartData() async {
    if (mounted) {
      setState(() {
        _isChartLoading = true;
        _chartError = null;
      });
    }

    try {
      final today = _dateOnly(DateTime.now());
      final startDate = today.subtract(const Duration(days: 6));

      final dailyStats = await DatabaseHelper.getDailyWorkoutStats(
        startDate: startDate,
        endDate: today,
      );

      final dates = <DateTime>[];
      final completion = <double?>[];

      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final stats = dailyStats[_dateKey(date)];

        dates.add(date);

        completion.add(
          stats?['completion'] == null
              ? null
              : (stats!['completion'] as num).toDouble(),
        );
      }

      if (!mounted) return;

      setState(() {
        _chartDates = dates;
        _completionData = completion;
        _selectedChartIndex = null;
        _isChartLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isChartLoading = false;
        _chartError = '图表加载失败';
      });

      debugPrint('读取训练趋势失败：$e');
    }
  }

  Future<void> _loadOverviewData() async {
    try {
      final today = _dateOnly(DateTime.now());
      final startDate = today.subtract(const Duration(days: 6));

      // 读取近7天的训练记录
      final workouts = await DatabaseHelper.getWorkoutTrend(
        startDate: startDate,
      );

      int workoutCount = 0;
      int totalSets = 0;
      int completedSets = 0;

      for (final workout in workouts) {
        final completedAt = DateTime.parse(workout['completed_at'] as String);

        final workoutDate = _dateOnly(completedAt);

        // 排除今天之后的记录
        if (workoutDate.isAfter(today)) continue;

        workoutCount++;

        totalSets += (workout['total_sets'] as num?)?.toInt() ?? 0;
        completedSets += (workout['completed_sets'] as num?)?.toInt() ?? 0;
      }

      final completion = totalSets > 0
          ? completedSets * 100.0 / totalSets
          : 0.0;

      if (!mounted) return;

      setState(() {
        _overviewWorkoutCount = workoutCount;
        _overviewCompletion = completion;
        _isOverviewLoading = false;
      });
    } catch (e) {
      debugPrint('读取训练概览失败：$e');

      if (!mounted) return;

      setState(() {
        _isOverviewLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('训练概览'),
          const SizedBox(height: 14),
          _buildOverview(),

          const SizedBox(height: 30),
          _buildChartSection(),
          const SizedBox(height: 30),
          _buildManagementSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Row(
      children: [
        Expanded(
          child: _overviewItem(
            icon: Icons.fitness_center,
            label: '训练次数',
            value: _isOverviewLoading ? '--' : '$_overviewWorkoutCount',
            unit: '次',
            subtitle: '近7天',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _overviewItem(
            icon: Icons.check_circle_outline,
            label: '计划完成度',
            value: _isOverviewLoading
                ? '--'
                : _overviewCompletion.toStringAsFixed(0),
            unit: '%',
            subtitle: '近7天',
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('训练趋势'),
        const SizedBox(height: 12),

        const Text('近 7 天', style: TextStyle(fontSize: 13, color: _secondary)),

        const SizedBox(height: 18),

        if (!_isChartLoading &&
            _chartError == null &&
            _completionData.any((value) => value != null))
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_chartAverage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '平均完成度',
                style: TextStyle(fontSize: 12, color: _secondary),
              ),
            ],
          ),

        const SizedBox(height: 24),

        SizedBox(
          height: 160,
          width: double.infinity,
          child: _isChartLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _blue,
                  ),
                )
              : _chartError != null
              ? Center(
                  child: Text(
                    _chartError!,
                    style: const TextStyle(color: _secondary),
                  ),
                )
              : !_completionData.any((value) => value != null)
              ? const Center(
                  child: Text(
                    '暂无训练数据',
                    style: TextStyle(fontSize: 13, color: _secondary),
                  ),
                )
              : _buildProgressBars(),
        ),
      ],
    );
  }

  Widget _buildProgressBars() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_chartDates.length, (index) {
        final progress = _completionData[index];
        final isSelected = _selectedChartIndex == index;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedChartIndex = isSelected ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isSelected ? 24 : 20,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF0F4),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.bottomCenter,
                        child: progress == null
                            ? const SizedBox.shrink()
                            : FractionallySizedBox(
                                heightFactor: (progress / 100).clamp(0.0, 1.0),
                                widthFactor: 1,
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF176FE5)
                                        : _blue,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _dateLabel(_chartDates[index]),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: _secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      progress == null
                          ? '--'
                          : '${progress.toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _blue : const Color(0xFF53657E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // 训练管理：两列面板
  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('训练管理'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildManagementTile(
              icon: Icons.insert_chart_outlined,
              title: '训练分析',
              onTap: _openTrainingAnalysis,
            ),
            _buildManagementTile(
              icon: Icons.calendar_month_outlined,
              title: '训练日历',
              onTap: _openTrainingCalendar,
            ),
            _buildManagementTile(
              icon: Icons.straighten,
              title: '身体测量',
              onTap: _openBodyMeasurement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _grey,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: Colors.black87),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: _black,
      ),
    );
  }

  Widget _overviewItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _secondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: _secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 14, color: _secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _secondary),
          ),
        ],
      ),
    );
  }
}
