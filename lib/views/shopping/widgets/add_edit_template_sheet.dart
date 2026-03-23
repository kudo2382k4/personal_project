import 'package:flutter/material.dart';
import '../../../data/implementations/services/gemini_service.dart';

// Đây là file hiển thị màn hình "Tạo Mẫu Mới" theo yêu cầu của người dùng.
const List<String> kTemplateCategories = [
  'Món ăn ngày Tết',
  'Đi chợ hàng ngày',
  'Sinh nhật',
  'Liên hoan',
  'Khác',
];

class AddEditTemplateSheet extends StatefulWidget {
  const AddEditTemplateSheet({super.key});

  @override
  State<AddEditTemplateSheet> createState() => _AddEditTemplateSheetState();
}

class _AddEditTemplateSheetState extends State<AddEditTemplateSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  String _selectedCategory = kTemplateCategories.first;
  bool _isFavorite = false;

  bool _isLoadingAi = false;

  static const Color _red = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _contentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _suggestContent() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty && _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề hoặc chọn nhóm trước.')),
      );
      return;
    }

    setState(() => _isLoadingAi = true);
    try {
      final suggestion = await GeminiService.suggestTemplateContent(
        title: title,
        category: _selectedCategory,
      );
      setState(() {
        _contentCtrl.text = suggestion;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề Sheet
          const Text(
            'Tạo mẫu mới',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Tiêu đề mẫu
          _buildLabel('TIÊU ĐỀ MẪU'),
          const SizedBox(height: 4),
          _buildField(_titleCtrl, 'Nhập tiêu đề (VD: Thực đơn mùng 1)'),
          const SizedBox(height: 12),

          // 2. Chọn nhóm phù hợp
          _buildLabel('CHỌN NHÓM PHÙ HỢP'),
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
                items: kTemplateCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Nội dung
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('NỘI DUNG'),
              TextButton.icon(
                onPressed: _isLoadingAi ? null : _suggestContent,
                icon: _isLoadingAi
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.auto_awesome, size: 16, color: Colors.orange.shade700),
                label: Text(
                  'Gợi ý AI',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Nhập nội dung mẫu hoặc dùng Gợi ý AI...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Đánh dấu yêu thích
          InkWell(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Đánh dấu yêu thích', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nút Lưu/Hủy
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: Xử lý lưu mẫu vào DB/ViewModel ở đây
                  // Demo: back về và trả về data
                  Navigator.pop(context, {
                    'title': _titleCtrl.text.trim(),
                    'category': _selectedCategory,
                    'content': _contentCtrl.text.trim(),
                    'isFavorite': _isFavorite,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Lưu mẫu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}
