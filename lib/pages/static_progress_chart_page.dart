
import 'package:flutter/material.dart';

class StaticProgressChartPage extends StatelessWidget {
  const StaticProgressChartPage({super.key});

  static const Color blue = Color(0xFF3288F5);
  static const Color trackColor = Color(0xFFEDF0F4);
  static const Color secondaryText = Color(0xFF8B96A8);
  static const Color primaryText = Color(0xFF111827);

  // 固定演示数据，暂不连接数据库
  static const List<ChartDay> demoData = [
  ChartDay('10/16', 60),
  ChartDay('10/17', 100),
  ChartDay('10/18', 0),
  ChartDay('10/19', 80),
  ChartDay('10/20', 90),
  ChartDay('10/21', 50),
  ChartDay('10/22', 100),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('静态图表预览'),
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '进度条式图表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '固定演示数据 · 暂无交互',
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            // 图表卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEAECEF),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 卡片标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '训练趋势',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      Row(
                        children: const [
                          Text(
                            '完成度',
                            style: TextStyle(
                              fontSize: 13,
                              color: blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '近 7 天',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 平均完成度
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '82%',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '日均完成度',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 七根竖向进度条
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: demoData.map((day) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 100,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(7),
                                    child: SizedBox(
                                      width: 20,
                                      height: 100,
                                      child: Stack(
                                        alignment:
                                            Alignment.bottomCenter,
                                        children: [
                                          // 灰色背景：剩余进度
                                          Container(
                                            color: trackColor,
                                          ),
                                          // 蓝色前景：已完成进度
                                          FractionallySizedBox(
                                            heightFactor:
                                                day.progress / 100,
                                            widthFactor: 1,
                                            alignment:
                                                Alignment.bottomCenter,
                                            child: Container(
                                              decoration:
                                                  const BoxDecoration(
                                                gradient:
                                                    LinearGradient(
                                                  begin:
                                                      Alignment.topCenter,
                                                  end: Alignment
                                                      .bottomCenter,
                                                  colors: [
                                                    Color(0xFF5BA5FF),
                                                    blue,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

// 日期：统一居中、固定字号
SizedBox(
  width: double.infinity,
  child: Text(
    day.date,
    textAlign: TextAlign.center,
    maxLines: 1,
    style: const TextStyle(
      fontSize: 10,
      height: 1.2,
      color: secondaryText,
    ),
  ),
),

const SizedBox(height: 5),

// 百分比：统一字号、字重和行高
SizedBox(
  width: double.infinity,
  child: Text(
    '${day.progress}%',
    textAlign: TextAlign.center,
    maxLines: 1,
    softWrap: false,
    style: const TextStyle(
      fontSize: 10,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF53657E),
    ),
  ),
),

                            ],
                          ),
                
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartDay {
  final String date;
  final int progress;

  const ChartDay(this.date, this.progress);
}
