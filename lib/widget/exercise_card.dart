import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/plan_data.dart';

class ExerciseCard extends StatefulWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.isEditingSets,
    required this.shakeController,
    required this.onEnterEditMode,
    required this.onDelete,
    this.isTrainingMode = false,
    this.completedSets = const {},
    this.onToggleSetCompleted,
  });

  final ExerciseData exercise;
  // 是否处于训练记录模式
  final bool isTrainingMode;

  // 已完成的组，使用从 0 开始的组索引
  final Set<int> completedSets;

  // 点击完成按钮时回调
  final ValueChanged<int>? onToggleSetCompleted;

  final bool isEditingSets;
  final AnimationController shakeController;

  final VoidCallback onEnterEditMode;
  final VoidCallback onDelete;

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late TextEditingController _nameController;

  final Map<SetData, TextEditingController> _weightControllers = {};
  final Map<SetData, TextEditingController> _repsControllers = {};

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.exercise.name);
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Flutter 复用卡片状态、但卡片对应的动作发生变化时，
    // 同步动作名称，避免显示上一个动作的内容。
    if (oldWidget.exercise != widget.exercise) {
      _nameController.text = widget.exercise.name;
    }
  }

  TextEditingController _weightControllerFor(SetData set) {
    return _weightControllers.putIfAbsent(
      set,
      () => TextEditingController(
        text: set.weight == null ? '' : _formatWeight(set.weight!),
      ),
    );
  }

  TextEditingController _repsControllerFor(SetData set) {
    return _repsControllers.putIfAbsent(
      set,
      () => TextEditingController(text: set.reps?.toString() ?? ''),
    );
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toString();
  }

  void _disposeSetControllers(SetData set) {
    _weightControllers.remove(set)?.dispose();
    _repsControllers.remove(set)?.dispose();
  }

  @override
  void dispose() {
    _nameController.dispose();

    for (final controller in _weightControllers.values) {
      controller.dispose();
    }

    for (final controller in _repsControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动作名称
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  readOnly: widget.isTrainingMode,
                  onChanged: (value) {
                    widget.exercise.name = value;
                  },
                  decoration: const InputDecoration(
                    hintText: "输入运动名称",
                    hintStyle: TextStyle(
                      color: Color(0xFFB8BCC3),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // 删除动作
              if (!widget.isTrainingMode)
                GestureDetector(
                  onTap: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("删除动作"),
                        content: const Text("确定要删除这个动作吗？"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              "取消",
                              style: TextStyle(color: Color(0xFF666666)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "删除",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      widget.onDelete();
                    }
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        "×",
                        style: TextStyle(
                          color: Color(0xFF8A8F98),
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // 表头
          _buildHeader(),

          const SizedBox(height: 7),

          // 组
          for (int i = 0; i < widget.exercise.sets.length; i++) ...[
            _buildSetRow(i),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 12),

          // 训练模式下不显示添加组按钮
          if (!widget.isTrainingMode) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    widget.exercise.sets.add(SetData());
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F3F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  "+ 添加组",
                  style: TextStyle(color: Color(0xFF101828), fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const SizedBox(
          width: 58,
          child: Center(
            child: Text(
              "组",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Center(
            child: Text(
              "KG",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Center(
            child: Text(
              "次",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),

        // 训练模式下显示完成列标题
        if (widget.isTrainingMode) ...[
          const SizedBox(width: 10),
          const SizedBox(
            width: 48,
            child: Center(
              child: Text(
                "完成",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSetRow(int index) {
    final set = widget.exercise.sets[index];
    final isCompleted = widget.completedSets.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0F6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: widget.isTrainingMode
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onEnterEditMode();
                    widget.shakeController.repeat(reverse: true);
                  },
            child: AnimatedBuilder(
              animation: widget.shakeController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.isTrainingMode
                      ? 0
                      : 0.03 * (widget.shakeController.value - 0.5),
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),

                  // 仅制定计划模式可以删除组
                  if (!widget.isTrainingMode && widget.isEditingSets)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (widget.exercise.sets.length <= 1) {
                            return;
                          }

                          setState(() {
                            final removedSet = widget.exercise.sets.removeAt(
                              index,
                            );
                            _disposeSetControllers(removedSet);
                          });
                        },
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFF168AF7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // KG
          Expanded(child: _buildWeightInput(set)),

          const SizedBox(width: 10),

          // 次
          Expanded(child: _buildRepsInput(set)),

          // 训练模式下显示完成按钮
          if (widget.isTrainingMode) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onToggleSetCompleted?.call(index);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isCompleted
                      ? const Color(0xFF168AF7)
                      : Colors.white,
                  foregroundColor: isCompleted
                      ? Colors.white
                      : const Color(0xFF8A8F98),
                  side: BorderSide(
                    color: isCompleted
                        ? const Color(0xFF168AF7)
                        : const Color(0xFFD0D5DD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.check, size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightInput(SetData set) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _weightControllerFor(set),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (value) {
          set.weight = double.tryParse(value);
        },
        decoration: InputDecoration(
          hintText: "-",
          hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 16),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFF168AF7), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildRepsInput(SetData set) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _repsControllerFor(set),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (value) {
          set.reps = int.tryParse(value);
        },
        decoration: InputDecoration(
          hintText: "-",
          hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 16),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFF168AF7), width: 1.2),
          ),
        ),
      ),
    );
  }
}
