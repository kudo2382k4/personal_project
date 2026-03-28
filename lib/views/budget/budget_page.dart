import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../viewmodels/budget/budget_viewmodel.dart';
import '../../viewmodels/shopping/shopping_viewmodel.dart';
import '../../di.dart';

class BudgetPage extends StatefulWidget {
  final int userId;
  const BudgetPage({super.key, required this.userId});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late final BudgetViewmodel _budgetVM;
  late final ShoppingViewmodel _shoppingVM;

  static const Color _red = Color(0xFFB71C1C);

  double get _totalEstimated {
    final all = [..._shoppingVM.needToBuy, ..._shoppingVM.alreadyBought];
    return all.fold(0.0, (s, i) => s + i.estimatedPrice);
  }

  double get _totalActual =>
      _shoppingVM.alreadyBought.fold(0.0, (s, i) => s + (i.actualPrice ?? 0));

  double get _remaining => _budgetVM.budgetLimit - _totalActual;

  String _fmt(double v) {
    final abs = v.abs().toInt();
    final formatted = abs.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted đ';
  }

  @override
  void initState() {
    super.initState();
    _budgetVM = BudgetViewmodel(userId: widget.userId);
    _shoppingVM = buildShoppingVM(widget.userId);

    _budgetVM.addListener(() => setState(() {}));
    _shoppingVM.addListener(() => setState(() {}));

    _budgetVM.loadBudget();
    _shoppingVM.loadItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetLimitCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildComparisonSection(),
            const SizedBox(height: 8),
            const Text(
              '* Chạm vào các cột để xem số tiền chi tiết',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thẻ hạn mức ngân sách ──
  Widget _buildBudgetLimitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HẠN MỨC NGÂN SÁCH',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _editBudget,
                child: const Icon(Icons.edit, color: Color(0xFFB71C1C), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fmt(_budgetVM.budgetLimit),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Thẻ trạng thái ngân sách ──
  Widget _buildStatusCard() {
    final isOver = _remaining < 0;
    final color = isOver ? Colors.red.shade600 : Colors.green.shade500;
    final icon = isOver ? Icons.warning_rounded : Icons.check_circle_outline;
    final title = isOver ? 'Vượt Ngân Sách!' : 'Ngân sách ổn định';
    final sub = isOver
        ? 'Bạn đã vượt ${_fmt(-_remaining)} so với hạn mức.'
        : 'Tuyệt vời! Bạn vẫn còn ${_fmt(_remaining)} để mua sắm thêm.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── So sánh chi tiết + Bar chart ──
  Widget _buildComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'So sánh Chi tiết',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('BIỂU ĐỒ CỘT', style: TextStyle(fontSize: 11, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
          ),
          child: _BudgetBarChart(
            estimated: _totalEstimated,
            actual: _totalActual,
            budget: _budgetVM.budgetLimit,
          ),
        ),
      ],
    );
  }

  // ── Dialog sửa ngân sách ──
  Future<void> _editBudget() async {
    final ctrl = TextEditingController(text: _budgetVM.budgetLimit.toInt().toString());
    String? _errorText;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cài đặt hạn mức ngân sách'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  suffixText: 'đ',
                  labelText: 'Số tiền',
                  errorText: _errorText,
                  errorStyle: const TextStyle(color: Colors.red),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (_) {
                  // Xoá lỗi khi người dùng bắt đầu sửa
                  if (_errorText != null) setDialogState(() => _errorText = null);
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Từ 1 đ đến 1.000.000.000 đ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(ctrl.text.trim()) ?? 0;
                if (amount <= 0) {
                  setDialogState(() => _errorText = 'Ngân sách phải lớn hơn 0 đ');
                  return;
                }
                if (amount > 1000000000) {
                  setDialogState(() => _errorText = 'Ngân sách không được vượt quá 1.000.000.000 đ');
                  return;
                }
                Navigator.of(dialogContext).pop();
                await _budgetVM.saveBudget(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Biểu đồ cột ──
class _BudgetBarChart extends StatefulWidget {
  final double estimated;
  final double actual;
  final double budget;
  const _BudgetBarChart({required this.estimated, required this.actual, required this.budget});

  @override
  State<_BudgetBarChart> createState() => _BudgetBarChartState();
}

class _BudgetBarChartState extends State<_BudgetBarChart> {
  int? _tapped; // 0=estimated, 1=actual, 2=budget

  String _fmt(double v) {
    final abs = v.abs().toInt();
    final formatted = abs.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted đ';
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = [widget.estimated, widget.actual, widget.budget, 1.0].reduce(math.max);
    const barW = 44.0;
    const maxH = 160.0;

    final bars = [
      _BarData(label: 'Dự kiến', value: widget.estimated, color: Colors.grey.shade400),
      _BarData(label: 'Thực tế', value: widget.actual, color: const Color(0xFFFF8C00)),
      _BarData(label: 'Ngân sách', value: widget.budget, color: const Color(0xFF42A5F5)),
    ];

    return Column(
      children: [
        if (_tapped != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${bars[_tapped!].label}: ${_fmt(bars[_tapped!].value)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        SizedBox(
          height: maxH + 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.asMap().entries.map((e) {
              final idx = e.key;
              final bar = e.value;
              final h = maxVal > 0 ? (bar.value / maxVal * maxH).clamp(4.0, maxH) : 4.0;

              return GestureDetector(
                onTap: () => setState(() => _tapped = _tapped == idx ? null : idx),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: barW,
                      height: h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bar.color.withValues(alpha: 0.8), bar.color],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: _tapped == idx
                            ? Border.all(color: Colors.black26, width: 1.5)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(bar.label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  const _BarData({required this.label, required this.value, required this.color});
}


