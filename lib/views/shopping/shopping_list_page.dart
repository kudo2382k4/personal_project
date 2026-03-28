import 'package:flutter/material.dart';
import '../../di.dart';
import '../../domain/entities/shopping_item.dart';
import '../../viewmodels/shopping/shopping_viewmodel.dart';
import '../../viewmodels/budget/budget_viewmodel.dart';
import 'widgets/add_edit_item_sheet.dart';
import 'widgets/need_to_buy_tab.dart';
import 'widgets/already_bought_tab.dart';
import 'shopping_route_page.dart';

class ShoppingListPage extends StatefulWidget {
  final int userId;
  final ShoppingViewmodel? sharedVm;
  const ShoppingListPage({super.key, required this.userId, this.sharedVm});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final ShoppingViewmodel _vm;
  late final BudgetViewmodel _budgetVM;

  static const Color _red = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _vm = widget.sharedVm ?? buildShoppingVM(widget.userId);
    _budgetVM = BudgetViewmodel(userId: widget.userId);
    // Chỉ loadItems nếu chưa có data (dùng ViewModel riêng)
    if (widget.sharedVm == null) _vm.loadItems();
    _budgetVM.loadBudget();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// Tổng tiền đã chi thực tế (các món đã mua)
  double get _totalActual =>
      _vm.alreadyBought.fold(0.0, (sum, i) => sum + (i.actualPrice ?? 0));

  /// Kiểm tra đã vượt ngân sách chưa
  bool get _isBudgetExceeded =>
      _budgetVM.budgetLimit > 0 && _totalActual >= _budgetVM.budgetLimit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        children: [
          // ── Header: tiêu đề + nút bản đồ ──
          Container(
            color: _red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách mua sắm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: _vm,
                  builder: (_, __) => _vm.needToBuy.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.map_outlined, color: Colors.white),
                          tooltip: 'Lộ trình mua sắm',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingRoutePage(items: _vm.needToBuy),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          // ── TabBar ──
          Container(
            color: _red,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Cần mua'),
                Tab(text: 'Đã mua'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                NeedToBuyTab(vm: _vm),
                AlreadyBoughtTab(vm: _vm),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) {
          // FAB chỉ hiện ở tab Cần mua
          if (_tabCtrl.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _handleAddTap(context),
            backgroundColor: _red,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        },
      ),
    );
  }

  /// Xử lý khi nhấn nút Add (+)
  Future<void> _handleAddTap(BuildContext context) async {
    // Reload budget để đảm bảo dữ liệu mới nhất
    await _budgetVM.loadBudget();

    if (_isBudgetExceeded) {
      // Hiện dialog cảnh báo vượt ngân sách
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 48),
          title: const Text(
            'Vượt ngân sách!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
          ),
          content: const Text(
            'Bạn đã vượt quá ngân sách đặt ra.\n\nĐể thêm món hàng mới, vui lòng vào mục Ngân sách và điều chỉnh lại hạn mức.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              ),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    await _openAdd(context);
  }

  Future<void> _openAdd(BuildContext context) async {
    final result = await showModalBottomSheet<ShoppingItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const AddEditItemSheet(),
    );
    if (result != null) await _vm.addItem(result);
  }
}
