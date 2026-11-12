import 'package:flutter/material.dart';

class WeightRecord {
  final double weight;
  final DateTime date;
  final String timeType;

  const WeightRecord({
    required this.weight,
    required this.date,
    required this.timeType,
  });
}

/// 从页面调用这个方法，返回用户录入的体重记录。
Future<WeightRecord?> showWeightEntrySheet(BuildContext context) {
  return showModalBottomSheet<WeightRecord>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    
    builder: (_) => const WeightEntrySheet(),
  );
}

class WeightEntrySheet extends StatefulWidget {
  const WeightEntrySheet({super.key});

  @override
  State<WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<WeightEntrySheet> {
  static const Color blue = Color(0xFF168BF5);
  static const Color textColor = Color(0xFF101828);
  static const Color secondaryColor = Color(0xFF98A2B3);
  

  final TextEditingController _weightController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '早晨空腹';

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择记录日期',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedDate = result;
    });
  }

  void _save() {
    final weight = double.tryParse(_weightController.text.trim());

    if (weight == null || !weight.isFinite || weight < 20 || weight > 500) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请输入有效的体重')));
      return;
    }

    final record = WeightRecord(
      weight: weight,
      date: _selectedDate,
      timeType: _selectedTime,
    );

    Navigator.of(context).pop(record);
  }

  String get _formattedDate {
    return '${_selectedDate.year}年'
        '${_selectedDate.month}月'
        '${_selectedDate.day}日';
  }

  
@override
Widget build(BuildContext context) {
  final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

  return AnimatedPadding(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            keyboardOpen ? 16 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部把手
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 标题栏
              Row(
                children: [
                  const Text(
                    '记录体重',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),    
                ],
              ),

              const SizedBox(height: 20),

              // 体重输入区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEAECF0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前体重',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            autofocus: false,
                            scrollPadding: const EdgeInsets.only(
                              bottom: 180,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                color: Color(0xFFD0D5DD),
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 日期
              const Text(
                '记录日期',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 9),

              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 19,
                        color: secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 记录时间
              const Text(
                '记录时间',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 9),

              Row(
                children: ['早晨空腹', '其他时间'].map((value) {
                  final selected = _selectedTime == value;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: value == '早晨空腹' ? 10 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTime = value;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEAF4FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? blue
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? blue : secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '保存记录',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
