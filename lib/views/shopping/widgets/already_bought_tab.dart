import 'package:flutter/material.dart';
import '../../../viewmodels/shopping/shopping_viewmodel.dart';

class AlreadyBoughtTab extends StatelessWidget {
  final ShoppingViewmodel vm;
  const AlreadyBoughtTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final items = vm.alreadyBought;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Chưa có món hàng nào đã mua', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final item = items[i];
            final diff = item.priceDifference;
            final diffColor = diff != null && diff >= 0 ? Colors.green : Colors.red;
            final diffLabel = diff != null
                ? '${diff >= 0 ? "-" : "+"}${diff.abs().toInt()} đ'
                : '';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Thực tế: ${item.actualPrice?.toInt() ?? 0} đ',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lệch: ${(item.priceDifference?.abs().toInt() ?? 0)} đ',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (diff != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: diffColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        diffLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
