import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../data/implementations/services/gemini_service.dart';

const List<String> kCategories = [
  'Đồ khô',
  'Thực phẩm tươi',
  'Bánh kẹo',
  'Đồ uống',
  'Hoa quả',
  'Trang trí',
  'Khác',
];

class AddEditItemSheet extends StatefulWidget {
  final ShoppingItem? item; // null = thêm mới, not null = sửa
  const AddEditItemSheet({super.key, this.item});

  @override
  State<AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<AddEditItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late String _selectedCategory;
  bool _isSuggestingPrice = false;

  static const Color _red = Color(0xFFB71C1C);

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _qtyCtrl = TextEditingController(text: (item?.quantity ?? 1).toString());
    _unitCtrl = TextEditingController(text: item?.unit ?? 'cái');
    _priceCtrl = TextEditingController(text: (item?.estimatedPrice ?? 0).toInt().toString());
    _selectedCategory = item?.category ?? kCategories.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            _isEditing ? 'Sửa thông tin món hàng' : 'Thêm món hàng mới',
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 16),

          // Tên món hàng
          _buildLabel('TÊN MÓN HÀNG'),
          const SizedBox(height: 4),
          _buildField(_nameCtrl, 'Nhập tên món hàng'),
          const SizedBox(height: 12),

          // Số lượng + Đơn vị
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SỐ LƯỢNG'),
                    const SizedBox(height: 4),
                    _buildField(_qtyCtrl, '1', type: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('ĐƠN VỊ'),
                    const SizedBox(height: 4),
                    _buildField(_unitCtrl, 'cái'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh mục
          _buildLabel('DANH MỤC'),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Giá dự kiến
          Row(
            children: [
              _buildLabel('GIÁ DỰ KIẾN (Đ)'),
              const Spacer(),
              GestureDetector(
                onTap: _isSuggestingPrice ? null : _suggestPrice,
                child: Row(
                  children: [
                    if (_isSuggestingPrice)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                      )
                    else
                      Icon(Icons.auto_awesome, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      _isSuggestingPrice ? 'Đang tư vấn...' : 'Tư vấn giá AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSuggestingPrice ? Colors.grey : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildField(_priceCtrl, '0', type: TextInputType.number),
          const SizedBox(height: 20),

          // Hủy / Thêm vào danh sách
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  _isEditing ? 'Lưu thay đổi' : 'Thêm vào danh sách',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildField(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Future<void> _suggestPrice() async {
    final itemName = _nameCtrl.text.trim();
    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên món hàng trước')),
      );
      return;
    }

    setState(() => _isSuggestingPrice = true);
    FocusScope.of(context).unfocus(); // Ẩn bàn phím

    try {
      final price = await GeminiService.suggestPrice(
        itemName: itemName,
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _priceCtrl.text = price.toInt().toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật giá gợi ý cho "$itemName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSuggestingPrice = false);
    }
  }

  void _onSubmit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final unit = _unitCtrl.text.trim().isEmpty ? 'cái' : _unitCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

    final item = _isEditing
        ? ShoppingItem(
            id: widget.item!.id,
            userId: widget.item!.userId,
            name: name,
            quantity: qty,
            unit: unit,
            category: _selectedCategory,
            estimatedPrice: price,
          )
        : ShoppingItem(
            userId: 0, // Sẽ được override bởi ViewModel
            name: name,
            quantity: qty,
            unit: unit,
            category: _selectedCategory,
            estimatedPrice: price,
          );
    Navigator.pop(context, item);
  }
}
