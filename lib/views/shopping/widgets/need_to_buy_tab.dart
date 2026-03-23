import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../viewmodels/shopping/shopping_viewmodel.dart';
import 'add_edit_item_sheet.dart';
import 'actual_price_dialog.dart';

class NeedToBuyTab extends StatelessWidget {
  final ShoppingViewmodel vm;
  const NeedToBuyTab({super.key, required this.vm});

  static const Color _red = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final items = vm.needToBuy;

        if (vm.loading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
        }
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Chưa có món hàng nào', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Nhấn + để thêm', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          );
        }

        // Nhóm theo danh mục
        final Map<String, List<ShoppingItem>> grouped = {};
        for (final item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header danh mục
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ),
                ...entry.value.map((item) => _buildItemCard(context, item)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ShoppingItem item) {
    return GestureDetector(
      onTap: () => _openEdit(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EE),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Row(
          children: [
            // Checkbox tích đã mua
            GestureDetector(
              onTap: () => _onCheckTap(context, item),
              child: const Icon(
                Icons.check_box_outline_blank,
                color: _red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Tên + số lượng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),

            // Giá dự kiến
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('DỰ KIẾN', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text(
                  '${item.estimatedPrice.toInt()} đ',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, ShoppingItem item) async {
    final result = await showModalBottomSheet<ShoppingItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddEditItemSheet(item: item),
    );
    if (result != null) await vm.updateItem(result);
  }

  Future<void> _onCheckTap(BuildContext context, ShoppingItem item) async {
    final price = await showDialog<double>(
      context: context,
      builder: (_) => ActualPriceDialog(item: item),
    );
    if (price != null && item.id != null) {
      await vm.markAsPurchased(item.id!, price);
    }
  }
}
