import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';
import 'package:flutter_application_1/pages/widget/weight_entry_sheet.dart';

class WeightTrendPage extends StatefulWidget {
  const WeightTrendPage({super.key});

  @override
  State<WeightTrendPage> createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends State<WeightTrendPage> {
  static const Color blue = Color(0xFF168BF5);
  static const Color textColor = Color(0xFF101828);
  static const Color secondaryColor = Color(0xFF98A2B3);
  static const Color gridColor = Color(0xFFF0F2F5);

  bool isLoading = true;

  // 近 7 天的体重数据，null 表示当天没有记录。
  List<double?> weights = List.filled(7, null);

  // 最近 7 天的日期。
  late List<DateTime> dates;

  // 所有历史记录中最新的一次体重。
  double? latestWeight;

  int selectedIndex = 6;

  @override
  void initState() {
    super.initState();

    _initDates();
    _loadWeightRecords();
  }

  void _initDates() {
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);

    dates = List.generate(
      7,
      (index) => todayDate.subtract(Duration(days: 6 - index)),
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDate(DateTime date) {
    return '${date.month} 月 ${date.day} 日';
  }

  String _weekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return weekdays[date.weekday - 1];
  }

  // 从数据库读取体重记录。
  Future<void> _loadWeightRecords() async {
    try {
      final records = await DatabaseHelper.getWeightRecords();

      final Map<String, double> dailyWeights = {};

      double? newestWeight;

      for (final record in records) {
        final weight = (record['weight'] as num).toDouble();
        final date = record['recorded_at'] as String;

        // 查询结果按日期、创建时间升序排列。
        // 同一天重复录入时，后面的记录覆盖前面的记录。
        dailyWeights[date.substring(0, 10)] = weight;

        newestWeight = weight;
      }

      final newWeights = dates.map((date) {
        return dailyWeights[_dateKey(date)];
      }).toList();

      // 默认选中最近一次有记录的日期。
      int newSelectedIndex = 6;

      for (int i = 6; i >= 0; i--) {
        if (newWeights[i] != null) {
          newSelectedIndex = i;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        weights = newWeights;
        latestWeight = newestWeight;
        selectedIndex = newSelectedIndex;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('读取体重记录失败：$e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // 打开录入面板并保存。
  Future<void> _openWeightEntrySheet() async {
    final result = await showWeightEntrySheet(context);

    if (result == null) return;

    try {
      await DatabaseHelper.saveWeightRecord(
        weight: result.weight,
        recordedAt: result.date,
        timeType: result.timeType,
      );

      if (!mounted) return;

      await _loadWeightRecords();
    } catch (e) {
      debugPrint('保存体重记录失败：$e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请稍后重试')),
      );
    }
  }

  // 最近 7 天第一条有记录的数据。
  double? get firstWeight {
    for (final weight in weights) {
      if (weight != null) return weight;
    }
    return null;
  }

  // 最近 7 天最后一条有记录的数据。
  double? get lastWeekWeight {
    for (int i = 6; i >= 0; i--) {
      if (weights[i] != null) return weights[i];
    }
    return null;
  }

  // 最近 7 天体重变化。
  double? get weeklyChange {
    if (firstWeight == null || lastWeekWeight == null) {
      return null;
    }

    int count = weights.where((weight) => weight != null).length;

    if (count < 2) return null;

    return lastWeekWeight! - firstWeight!;
  }

  double? get selectedWeight => weights[selectedIndex];

  // 选中日期之前最近一次有记录的体重。
  double? get previousRecordedWeight {
    for (int i = selectedIndex - 1; i >= 0; i--) {
      if (weights[i] != null) return weights[i];
    }
    return null;
  }

  // 根据实际体重生成连续折线段。
  // 中间缺失日期时，不连接两侧数据。
  List<LineChartBarData> _buildLineBars() {
    final List<LineChartBarData> bars = [];

    List<FlSpot> currentSpots = [];

    void addSegment() {
      if (currentSpots.isEmpty) return;

      bars.add(
        LineChartBarData(
          spots: List.from(currentSpots),
          isCurved: true,
          curveSmoothness: 0.18,
          color: blue,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: spot.x.toInt() == selectedIndex ? 3.5 : 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: blue,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                blue.withValues(alpha: 0.12),
                blue.withValues(alpha: 0.00),
              ],
            ),
          ),
        ),
      );

      currentSpots = [];
    }

    for (int i = 0; i < weights.length; i++) {
      final weight = weights[i];

      if (weight == null) {
        addSegment();
      } else {
        currentSpots.add(FlSpot(i.toDouble(), weight));
      }
    }

    addSegment();

    return bars;
  }

  // 根据体重数据动态计算纵轴范围。
  double get chartMinY {
    final values = weights.whereType<double>().toList();

    if (values.isEmpty) return 0;

    final minValue = values.reduce((a, b) => a < b ? a : b);

    return minValue - 0.8;
  }

  double get chartMaxY {
    final values = weights.whereType<double>().toList();

    if (values.isEmpty) return 10;

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return maxValue + 0.8;
  }

  @override
  Widget build(BuildContext context) {
    final change = weeklyChange;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '体重趋势',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openWeightEntrySheet,
            icon: const Icon(
              Icons.add,
              color: textColor,
              size: 26,
            ),
            tooltip: '记录体重',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: blue),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前体重',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 当前体重
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          latestWeight?.toStringAsFixed(1) ?? '--',
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 42,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 7, bottom: 5),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (change != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 时间范围
                    Row(
                      children: [
                        const Text(
                          '体重变化',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '近 7 天',
                            style: TextStyle(
                              color: blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 趋势图
                    SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Center(
                        child: SizedBox(
                          width: 290,
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: 6,
                              minY: chartMinY,
                              maxY: chartMaxY,
                              clipData: const FlClipData.none(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 0.4,
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: gridColor,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                    reservedSize: 0,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();

                                      if (index < 0 || index >= dates.length) {
                                        return const SizedBox.shrink();
                                      }

                                      final hasData = weights[index] != null;
                                      final isSelected =
                                          selectedIndex == index;

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          _weekday(dates[index]),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected
                                                ? blue
                                                : hasData
                                                    ? const Color(0xFF667085)
                                                    : const Color(0xFFD0D5DD),
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              lineBarsData: _buildLineBars(),

                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                touchCallback: (event, response) {
                                  final spots = response?.lineBarSpots;

                                  if (spots == null || spots.isEmpty) return;

                                  final index = spots.first.x.toInt();

                                  if (index >= 0 &&
                                      index < weights.length &&
                                      weights[index] != null &&
                                      index != selectedIndex) {
                                    setState(() {
                                      selectedIndex = index;
                                    });
                                  }
                                },
                                getTouchedSpotIndicator: (
                                  barData,
                                  spotIndexes,
                                ) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      const FlLine(
                                        color: Color(0xFFB8D9FF),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                      ),
                                      FlDotData(
                                        getDotPainter: (
                                          spot,
                                          percent,
                                          bar,
                                          index,
                                        ) {
                                          return FlDotCirclePainter(
                                            radius: 3,
                                            color: blue,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList();
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => textColor,
                                  tooltipPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  getTooltipItems: (spots) {
                                    return spots.map((spot) {
                                      return LineTooltipItem(
                                        '${spot.y.toStringAsFixed(1)} kg',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 选中日期详情
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekday(dates[selectedIndex])} · ${_formatDate(dates[selectedIndex])}',
                            style: const TextStyle(
                              color: secondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                selectedWeight?.toStringAsFixed(1) ?? '--',
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 6, bottom: 3),
                                child: Text(
                                  'kg',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (selectedWeight != null &&
                                  previousRecordedWeight != null)
                                Text(
                                  '${selectedWeight! - previousRecordedWeight! > 0 ? '+' : ''}${(selectedWeight! - previousRecordedWeight!).toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: selectedWeight! -
                                                previousRecordedWeight! >
                                            0
                                        ? const Color(0xFFDC6803)
                                        : const Color(0xFF039855),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '体重会受饮水、饮食和训练影响，关注长期趋势即可。',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}