import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';

import 'training_month_page.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({super.key});

  @override
  State<TrainingCalendarPage> createState() => _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends State<TrainingCalendarPage> {
  static const Color _backgroundColor = Colors.white;
  static const Color _titleColor = Color(0xFF101828);
  static const Color _emptyDayColor = Color(0xFFE5E7EB);
  static const Color _trainingDayColor = Color(0xFF168BF5);
  static const Color _secondaryTextColor = Color(0xFF667085);

  // 显示当前年份。
  int _year = DateTime.now().year;

  // key 为月份，value 为该月有训练记录的日期集合。
  // 例如：{9: {3, 7, 16, 21}}
  Map<int, Set<int>> _trainingDaysByMonth = {};

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  // 从 SQLite 读取真实训练记录，并按月份整理日期。
  Future<void> _loadWorkouts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final workouts = await DatabaseHelper.getWorkoutHistory();

      final trainingDays = <int, Set<int>>{};

      for (final workout in workouts) {
        final completedAt = workout['completed_at'] as String?;
        if (completedAt == null) continue;

        final date = DateTime.tryParse(completedAt);
        if (date == null || date.year != _year) continue;

        trainingDays.putIfAbsent(date.month, () => <int>{});
        trainingDays[date.month]!.add(date.day);
      }

      if (!mounted) return;

      setState(() {
        _trainingDaysByMonth = trainingDays;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });

      debugPrint('加载训练日历失败：$e');
    }
  }


  Future<void> _showYearPicker() async {
  final currentYear = DateTime.now().year;
  final initialYear = _year;

  final selectedYear = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    builder: (context) {
      int tempYear = initialYear;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SizedBox(
              height: 230,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                        const Text(
                          '选择年份',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101828),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, tempYear),
                          child: const Text(
                            '完成',
                            style: TextStyle(
                              color: Color(0xFF168BF5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(
                        initialItem: (currentYear + 5) - initialYear,
                      ),
                      itemExtent: 42,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          tempYear = currentYear + 5 - index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 11,
                        builder: (context, index) {
                          final year = currentYear + 5 - index;

                          return Center(
                            child: Text(
                              '$year 年',
                              style: TextStyle(
                                fontSize: year == tempYear ? 20 : 16,
                                fontWeight: year == tempYear
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: year == tempYear
                                    ? Color(0xFF101828)
                                    : const Color(0xFF98A2B3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (!mounted) return;

  if (selectedYear != null && selectedYear != _year) {
    setState(() {
      _year = selectedYear;
    });

    _loadWorkouts();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '训练日历',
          style: TextStyle(
            color: _titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
  alignment: Alignment.centerLeft,
  child: Transform.translate(
    offset: const Offset(-16, 0),
                child: InkWell(
                  onTap: _showYearPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_year',
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: _secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ),
              
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Text(
                          '训练记录加载失败',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadWorkouts,
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const columnGap = 20.0;
                    const rowGap = 32.0;

                    final itemWidth =
                        (constraints.maxWidth - columnGap * 2) / 3;

                    return Wrap(
                      spacing: columnGap,
                      runSpacing: rowGap,
                      children: List.generate(12, (index) {
                        final month = index + 1;

                        return SizedBox(
                          width: itemWidth,
                          child: _buildMonth(
                            context,
                            month,
                            _trainingDaysByMonth[month] ?? <int>{},
                          ),
                        );
                      }),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonth(BuildContext context, int month, Set<int> trainingDays) {
    final daysInMonth = DateUtils.getDaysInMonth(_year, month);
    final firstWeekday = DateTime(_year, month, 1).weekday;
    final leadingEmptyCells = firstWeekday - 1;

    final cells = <Widget>[];

    for (int i = 0; i < leadingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isTrainingDay = trainingDays.contains(day);

      cells.add(
        DecoratedBox(
          decoration: BoxDecoration(
            color: isTrainingDay ? _trainingDayColor : _emptyDayColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingMonthPage(year: _year, month: month),
          ),
        );

        // 从月视图返回后，重新读取数据库。
        if (mounted) {
          await _loadWorkouts();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$month月',
            style: const TextStyle(
              color: _titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: cells,
          ),
        ],
      ),
    );
  }
}
