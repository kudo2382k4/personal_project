import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';

class ActualPriceDialog extends StatefulWidget {
  final ShoppingItem item;
  const ActualPriceDialog({super.key, required this.item});

  @override
  State<ActualPriceDialog> createState() => _ActualPriceDialogState();
}

class _ActualPriceDialogState extends State<ActualPriceDialog> {
  late final TextEditingController _ctrl;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.item.estimatedPrice;
    _ctrl = TextEditingController(text: _sliderValue.toInt().toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tính maxSlider dựa trên giá dự kiến, tối thiểu là 1 triệu
    double maxSlider = widget.item.estimatedPrice * 2 > 0
        ? widget.item.estimatedPrice * 2
        : 1000000.0;
    
    // Nếu giá trị thanh trượt vượt quá maxSlider dự kiến, nới rộng maxSlider ra
    if (_sliderValue > maxSlider) {
      maxSlider = _sliderValue;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFFFF1EE),
      child: Padding(
        padding: const EdgeInsets.all(20), // Xóa viewInsets.bottom vì Dialog đã tự xử lý
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi giá thực tế',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
            ),
            const SizedBox(height: 6),
            Text('Món hàng: ${widget.item.name}', style: const TextStyle(fontSize: 13)),
            Text(
              'Dự kiến: ${widget.item.estimatedPrice.toInt()} đ',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Ô nhập giá
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB71C1C), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (v) {
                        final val = double.tryParse(v) ?? 0;
                        // Không clamp để cho phép nhập giá lớn hơn maxSlider
                        // maxSlider sẽ tự mở rộng trong build()
                        setState(() => _sliderValue = val < 0 ? 0 : val);
                      },
                    ),
                  ),
                  const Text('đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Slider
            Slider(
              value: _sliderValue.clamp(0, maxSlider),
              min: 0,
              max: maxSlider,
              activeColor: const Color(0xFFB71C1C),
              onChanged: (v) {
                setState(() {
                  _sliderValue = v;
                  _ctrl.text = v.toInt().toString();
                });
              },
            ),
            const SizedBox(height: 8),

            // Gợi ý nhanh (+10k, +50k, ...)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAddChip(10000),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(50000),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(100000),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(_ctrl.text.trim()) ?? _sliderValue;
                    Navigator.pop(context, price);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Xác nhận chi phí', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(double amount) {
    return ActionChip(
      label: Text(
        '+${(amount / 1000).toInt()}k',
        style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFB71C1C)),
      onPressed: () {
        setState(() {
          _sliderValue += amount;
          _ctrl.text = _sliderValue.toInt().toString();
        });
      },
    );
  }
}
