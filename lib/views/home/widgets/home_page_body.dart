
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../di.dart';
import '../../../viewmodels/shopping/shopping_viewmodel.dart';
import '../../../viewmodels/budget/budget_viewmodel.dart';
import '../../../data/implementations/services/gemini_service.dart';
import '../../../domain/entities/meal_suggestion.dart';
import '../../../domain/entities/shopping_item.dart';

class HomePageBody extends StatefulWidget {
  final int userId;
  final VoidCallback? onNavigateToBudget;
  final ValueNotifier<int>? refreshTicker;
  final ShoppingViewmodel? sharedVm;
  const HomePageBody({
    super.key,
    required this.userId,
    this.onNavigateToBudget,
    this.refreshTicker,
    this.sharedVm,
  });

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  late final ShoppingViewmodel _vm;
  late final BudgetViewmodel _budgetVM;

  // ── Gemini suggestion state ──
  List<MealSuggestion> _meals = [];
  bool _loadingSuggestion = false;
  String? _suggestionError;

  @override
  void initState() {
    super.initState();
    _vm = widget.sharedVm ?? buildShoppingVM(widget.userId);
    _budgetVM = BudgetViewmodel(userId: widget.userId);
    _vm.addListener(_onVmChanged);
    _budgetVM.addListener(_onVmChanged);
    if (widget.sharedVm == null) _vm.loadItems();
    _budgetVM.loadBudget();
    widget.refreshTicker?.addListener(_onRefresh);
  }

  void _onRefresh() {
    _budgetVM.loadBudget();
    _vm.loadItems();
  }

  @override
  void dispose() {
    widget.refreshTicker?.removeListener(_onRefresh);
    _vm.removeListener(_onVmChanged);
    _budgetVM.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() => setState(() {});

  // ── Tính toán thống kê ──
  int get _totalItems => _vm.needToBuy.length + _vm.alreadyBought.length;
  int get _boughtCount => _vm.alreadyBought.length;

  double get _totalActual =>
      _vm.alreadyBought.fold(0.0, (sum, i) => sum + (i.actualPrice ?? 0));

  // Progress dựa trên ngân sách đặt trong BudgetPage
  double get _budgetProgress {
    final limit = _budgetVM.budgetLimit;
    if (limit <= 0) return 0.0;
    return (_totalActual / limit).clamp(0.0, 1.0);
  }

  double get _remaining {
    final limit = _budgetVM.budgetLimit;
    return limit - _totalActual; // có thể âm nếu vượt ngân sách
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel = '$_boughtCount/$_totalItems';
    final actualLabel = '${_formatCurrency(_totalActual)} đ';
    final pct = (_budgetProgress * 100).toInt();
    final remaining = _remaining.clamp(0.0, double.infinity); // chart chỉ hiện >= 0

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 2 thẻ thống kê ──
          Row(
            children: [
              Expanded(child: _buildStatCard(title: 'Tiến độ mua sắm', value: progressLabel, valueColor: Colors.black87)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(title: 'Tổng thực tế', value: actualLabel, valueColor: const Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 20),

          // ── Banner ngân sách ──
          GestureDetector(
            onTap: widget.onNavigateToBudget,
            child: _buildBudgetBanner(),
          ),
          const SizedBox(height: 12),

          // ── Biểu đồ ngân sách ──
          const Text(
            'Biểu đồ ngân sách',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _buildBudgetChart(pct: pct, actual: _totalActual, remaining: remaining),
          const SizedBox(height: 20),

          // ── Gợi ý thông minh ──
          _buildSmartSuggestion(),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBudgetBanner() {
    final isOver = _remaining < 0;
    final progress = _budgetVM.budgetLimit > 0
        ? (_totalActual / _budgetVM.budgetLimit).clamp(0.0, 1.0)
        : 0.0;

    const Color red = Color(0xFFB71C1C);
    const Color darkRed = Color(0xFF7F0000);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkRed, red],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _budgetVM.loading
          ? const Center(
              child: SizedBox(
                height: 16, width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tiêu đề ──
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    const Text(
                      'NGÂN SÁCH',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Số tiền còn lại + chi tiết ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOver ? 'Vượt ngân sách!' : 'Còn lại',
                            style: TextStyle(
                              color: isOver ? Colors.yellow.shade200 : Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOver ? '−${_formatCurrency(-_remaining)} đ' : '${_formatCurrency(_remaining)} đ',
                            style: TextStyle(
                              color: isOver ? Colors.yellow.shade100 : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Đã chi: ${_formatCurrency(_totalActual)} đ', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          'Hạn mức: ${_budgetVM.budgetLimit > 0 ? "${_formatCurrency(_budgetVM.budgetLimit)} đ" : "Chưa đặt"}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Thanh tiến trình ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOver ? Colors.yellow.shade300 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }


  Widget _buildBudgetChart({required int pct, required double actual, required double remaining}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _CirclePainter(progress: _budgetProgress),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00)),
                    ),
                    const Text('Đã chi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(color: const Color(0xFFFF8C00), label: 'Đã chi', value: '${_formatCurrency(actual)} đ'),
              const SizedBox(width: 24),
              _buildLegend(
                color: Colors.grey.shade300,
                label: 'Còn lại',
                value: '${_formatCurrency(remaining > 0 ? remaining : 0)} đ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label, required String value}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartSuggestion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gợi ý món ăn ngày Tết 🧧',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _loadingSuggestion
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : GestureDetector(
                      onTap: _fetchSuggestion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _meals.isEmpty ? 'Gợi ý ngay ✨' : 'Gợi ý lại 🔄',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
            ],
          ),

          // ── Kết quả gợi ý ──
          if (_meals.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_meals.length, (i) => _buildMealCard(_meals[i])),
          ] else if (_suggestionError != null) ...[
            const SizedBox(height: 10),
            Text('⚠️ $_suggestionError',
                style: TextStyle(color: Colors.yellow.shade200, fontSize: 12)),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              _vm.needToBuy.isEmpty && _vm.alreadyBought.isEmpty
                  ? 'Nhấn "Gợi ý ngay" để nhận gợi ý món ăn từ AI 🤖'
                  : 'AI sẽ gợi ý dựa trên ${_vm.needToBuy.length + _vm.alreadyBought.length} nguyên liệu trong danh sách.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealCard(MealSuggestion meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tên món + nút thêm ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🍽️ ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  meal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _addMealToList(meal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart, size: 13, color: Color(0xFF6A1B9A)),
                      SizedBox(width: 4),
                      Text(
                        'Thêm vào DS',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Badge category ──
          if (meal.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_outline, color: Colors.white60, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    meal.category,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],

          // ── Mô tả ──
          if (meal.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meal.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],

          // ── Nguyên liệu có định lượng ──
          if (meal.mainIngredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              '📦 Nguyên liệu cần mua:',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...meal.mainIngredients.map((ing) {
              final alreadyHave = [
                ..._vm.needToBuy,
                ..._vm.alreadyBought,
              ].any((i) => i.name.toLowerCase().trim() == ing.item.toLowerCase().trim());

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    // Dot hoặc checkmark
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: alreadyHave
                            ? Colors.green.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: alreadyHave
                              ? Colors.greenAccent.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: alreadyHave
                            ? const Icon(Icons.check, size: 11, color: Colors.greenAccent)
                            : Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tên nguyên liệu
                    Expanded(
                      child: Text(
                        ing.item,
                        style: TextStyle(
                          color: alreadyHave ? Colors.greenAccent : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Định lượng + đơn vị
                    if (ing.quantity.isNotEmpty || ing.unit.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ing.quantity} ${ing.unit}'.trim(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchSuggestion() async {
    setState(() {
      _loadingSuggestion = true;
      _suggestionError = null;
      _meals = [];
    });
    try {
      final ingredients =
          [..._vm.needToBuy, ..._vm.alreadyBought].map((i) => i.name).toList();
      final result = await GeminiService.suggestMealsStructured(ingredients);
      if (mounted) setState(() => _meals = result);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _suggestionError = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingSuggestion = false);
    }
  }

  /// Thêm nguyên liệu của [meal] chưa có trong danh sách vào danh sách mua sắm
  Future<void> _addMealToList(MealSuggestion meal) async {
    final existingNames = [
      ..._vm.needToBuy,
      ..._vm.alreadyBought,
    ].map((i) => i.name.toLowerCase().trim()).toSet();

    final toAdd = meal.mainIngredients
        .where((ing) => !existingNames.contains(ing.item.toLowerCase().trim()))
        .toList();

    if (toAdd.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tất cả nguyên liệu đã có trong danh sách!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    for (final ing in toAdd) {
      final qty = int.tryParse(ing.quantity) ?? 1;
      await _vm.addItem(ShoppingItem(
        userId: widget.userId,
        name: ing.item,
        quantity: qty,
        unit: ing.unit.isNotEmpty ? ing.unit : 'phần',
        category: 'Thực phẩm tươi',
        estimatedPrice: 0,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🛒 Đã thêm ${toAdd.length} nguyên liệu của "${meal.name}" vào danh sách!'),
          backgroundColor: const Color(0xFF6A1B9A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  String _formatCurrency(double value) {
    final abs = value.abs().toInt();
    return abs.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  const _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = const Color(0xFFFF8C00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}
