import 'package:flutter/material.dart';
import '../../di.dart';
import '../../domain/entities/shopping_item.dart';
import '../../viewmodels/shopping/shopping_viewmodel.dart';
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

  static const Color _red = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _vm = widget.sharedVm ?? buildShoppingVM(widget.userId);
    // Chỉ loadItems nếu chưa có data (dùng ViewModel riêng)
    if (widget.sharedVm == null) _vm.loadItems();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

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
            onPressed: () => _openAdd(context),
            backgroundColor: _red,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        },
      ),
    );
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
