import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/plan_data.dart';

import 'package:flutter_application_1/widget/exercise_card.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({
    super.key,
    this.initialPlan,
    this.isEditing = false,
  });

  // 编辑时传入原计划
  final PlanData? initialPlan;

  // 区分新建和编辑模式
  final bool isEditing;

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController planNameController = TextEditingController();

  late final PlanData plan;

  bool isEditingSets = false;

  late AnimationController _shakeController;

  // 复制计划，避免编辑过程中直接修改原计划
  PlanData _copyPlan(PlanData source) {
    return PlanData(
      planName: source.planName,
      exercises: source.exercises.map((exercise) {
        return ExerciseData(
          name: exercise.name,
          sets: exercise.sets.map((set) {
            return SetData(
              weight: set.weight,
              reps: set.reps,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();

    // 编辑模式复制原计划，新建模式创建空计划
    plan = widget.isEditing && widget.initialPlan != null
        ? _copyPlan(widget.initialPlan!)
        : PlanData();

    planNameController.text = plan.planName;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    planNameController.dispose();
    super.dispose();
  }

  // 进入组数编辑模式
  void _enterEditMode() {
    setState(() {
      isEditingSets = true;
    });

    _shakeController.repeat(reverse: true);
  }

  // 退出组数编辑模式
  void _exitEditMode() {
    if (!isEditingSets) return;

    setState(() {
      isEditingSets = false;
    });

    _shakeController.stop();
  }

  // 保存计划
  void _savePlan() {
    plan.planName = planNameController.text.trim();

    HapticFeedback.lightImpact();

    // 返回编辑后的副本，由 HomePage 决定新增或更新
    Navigator.pop(context, plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isEditing ? '编辑计划' : '制定计划',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF168AF7),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _exitEditMode,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '计划名称',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: planNameController,
                onChanged: (value) {
                  plan.planName = value;
                },
                decoration: InputDecoration(
                  hintText: '输入计划名称',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF168AF7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '动作',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),

              // 动作卡片
              ...plan.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;

                return ExerciseCard(
                  exercise: exercise,
                  isEditingSets: isEditingSets,
                  shakeController: _shakeController,
                  onEnterEditMode: _enterEditMode,
                  onDelete: () {
                    setState(() {
                      plan.exercises.removeAt(index);
                    });
                  },
                );
              }),

              // 添加动作
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFF168AF7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.lightImpact();

                      setState(() {
                        plan.exercises.add(
                          ExerciseData(sets: [SetData()]),
                        );
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF168AF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          '+ 添加运动',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 300),
            ],
          ),
        ),
      ),
    );
  }
}