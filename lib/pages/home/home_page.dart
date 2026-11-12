import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';
import '../workout_detail_page.dart';
import 'package:flutter_application_1/pages/training_page.dart';
import 'package:flutter_application_1/pages/my_page.dart';
import 'package:flutter_application_1/utils/typeface.dart';
import 'package:flutter_application_1/pages/create_plan_page.dart';
import 'package:flutter_application_1/pages/view_plan_page.dart';
import 'package:flutter_application_1/plan_data.dart';
import 'package:flutter_application_1/widget/plan_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
  
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  

  // 暂时将计划保存在内存中
  final List<PlanData> plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  

  Future<void> _loadPlans() async {
    try {
      final savedPlans = await DatabaseHelper.getFullPlans();

      if (!mounted) return;

      setState(() {
        plans
          ..clear()
          ..addAll(savedPlans);
      });
    } catch (e) {
      debugPrint('加载训练计划失败：$e');
    }
  }

  // 打开制定计划页面，并接收返回的计划

  Future<void> _createPlan() async {
    final PlanData? result = await Navigator.push<PlanData>(
      context,
      MaterialPageRoute(builder: (context) => CreatePlanPage()),
    );

    if (result == null) return;

    try {
      // 1. 把完整计划写入数据库
      final planId = await DatabaseHelper.savePlan(result);

      // 2. 数据库保存成功后，再更新首页列表
      if (!mounted) return;

      await _loadPlans();
      debugPrint('计划保存成功，数据库 ID：$planId');
    } catch (e) {
      debugPrint('计划保存失败：$e');
    }
  }

  Future<void> _editPlan(int index) async {
    final PlanData? result = await Navigator.push<PlanData>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreatePlanPage(initialPlan: plans[index], isEditing: true),
      ),
    );

    if (result == null) return;

    try {
      // 直接从当前计划获取数据库 ID
      final planId = plans[index].id;

      if (planId == null) {
        throw Exception('该计划缺少数据库 ID，请重新加载计划');
      }

      // 更新数据库
      await DatabaseHelper.updatePlan(planId, result);

      // 保留原计划的数据库 ID
      result.id = planId;

      if (!mounted) return;

      setState(() {
        plans[index] = result;
      });

      // 编辑成功后，回到主页
      Navigator.pop(context);
    } catch (e) {
      debugPrint('更新训练计划失败：$e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('更新失败，请稍后重试')));
    }
  }

  Future<void> _deletePlan(int index) async {
    // 先询问用户是否确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除训练计划'),
        content: Text(
          '确定删除「${plans[index].planName.isEmpty ? '未命名计划' : plans[index].planName}」吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // 查询数据库，取得对应计划的 ID
      final planId = plans[index].id;

      if (planId == null) {
        throw Exception('该计划缺少数据库 ID，请重新加载计划');
      }

      // 删除数据库记录
      await DatabaseHelper.deletePlan(planId);

      if (!mounted) return;

      // 删除首页内存列表中的计划
      setState(() {
        plans.removeAt(index);
      });
    } catch (e) {
      debugPrint('删除训练计划失败：$e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试')));
    }
  }

  Future<void> _startTraining(PlanData plan) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => TrainingPage(plan: plan)),
    );

    if (!mounted || result == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailPage(workoutId: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text('训练', style: AppTextStyles.pageTitle),
            const Spacer(),

            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5F57),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),

            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFFBD2E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),

            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF28C840),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),

      body: selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 首页提示
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '今天也保持一点进步。',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text('计划', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 20),

                  // 制定计划 / 查看计划
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _createPlan,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.note_add_outlined, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '制定计划',
                                    style: AppTextStyles.actiontitle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewPlanPage(
                                  plans: plans,
                                  onEditPlan: _editPlan,
                                  onDeletePlan: _deletePlan,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.list_alt, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '查看计划',
                                    style: AppTextStyles.actiontitle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Text('我的计划', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 15),

                  // 根据 plans 动态显示计划卡片
                  if (plans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '还没有计划，先制定一个吧。',
                          style: TextStyle(color: Colors.black45, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...plans.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlanCard(
                          plan: plan,
                          onStartTraining: () => _startTraining(plan),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const MyPage(),

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: selectedIndex == 0
                      ? const Color(0xFFE8F1FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.home_outlined,
                  color: selectedIndex == 0
                      ? const Color(0xFF007AFF)
                      : Colors.black,
                  size: 24,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: selectedIndex == 1
                      ? const Color(0xFFE8F1FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: selectedIndex == 1
                      ? const Color(0xFF007AFF)
                      : Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
