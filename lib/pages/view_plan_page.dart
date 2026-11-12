
import 'package:flutter/material.dart';
import 'package:flutter_application_1/plan_data.dart';
import 'package:flutter_application_1/widget/plan_manage_card.dart';

class ViewPlanPage extends StatefulWidget {
  const ViewPlanPage({
    super.key,
    required this.plans,
    required this.onEditPlan,
    required this.onDeletePlan,
  });

  final List<PlanData> plans;
  final Future<void> Function(int index) onEditPlan;
  final Future<void> Function(int index) onDeletePlan;

  @override
  State<ViewPlanPage> createState() => _ViewPlanPageState();
}

class _ViewPlanPageState extends State<ViewPlanPage> {
  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '查看计划',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: plans.isEmpty
          ? const Center(
              child: Text(
                '还没有计划，先制定一个吧。',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 14,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PlanManageCard(
                    plan: plans[index],
                    onEdit: () => widget.onEditPlan(index),
                    onDelete: () async {
                      await widget.onDeletePlan(index);

                      if (!mounted) return;

                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
