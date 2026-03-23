import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String userName;

  const ProfilePage({super.key, required this.userId, required this.userName});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final ProfileViewmodel _vm;
  late final TabController _tabController;

  // Controllers – tab Thông tin
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  // Controllers – tab Đổi mật khẩu
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const _primary = Color(0xFF1A237E); // deep indigo
  static const _accent = Color(0xFF3949AB);
  static const _gold = Color(0xFFFFCA28);

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewmodel(userId: widget.userId);
    _tabController = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _vm.loadProfile();
    if (mounted) {
      _nameCtrl.text = _vm.name;
      _phoneCtrl.text = _vm.phone;
      _emailCtrl.text = _vm.email;
      _addressCtrl.text = _vm.address;
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          // ── Header / Avatar ──
          _buildHeader(),
          // ── Tabs ──
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.person_outline), text: 'Thông tin'),
                Tab(icon: Icon(Icons.lock_outline), text: 'Đổi mật khẩu'),
              ],
            ),
          ),
          // ── Tab body ──
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (_, child) {
                if (_vm.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildPasswordTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────
  Widget _buildHeader() {
    final initials = _vm.name.isNotEmpty
        ? _vm.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : widget.userName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final hasAvatar = _vm.avatarPath != null && _vm.avatarPath!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          // Avatar + camera button overlay
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 3),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.file(File(_vm.avatarPath!), fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                  ),
                ),
                // Camera icon overlay
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: _primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _vm.name.isNotEmpty ? _vm.name : widget.userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (_vm.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_vm.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          const Text(
            'Nhấn vào ảnh để thay đổi',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Tab 1: Thông tin cá nhân
  // ──────────────────────────────────────────
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Thông tin cá nhân',
            icon: Icons.person,
            children: [
              _buildField(label: 'Họ và tên', controller: _nameCtrl, icon: Icons.badge_outlined),
              _buildField(label: 'Số điện thoại', controller: _phoneCtrl, icon: Icons.phone_outlined, type: TextInputType.phone),
              _buildField(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, type: TextInputType.emailAddress),
              _buildField(label: 'Địa chỉ', controller: _addressCtrl, icon: Icons.home_outlined, maxLines: 2),
            ],
          ),
          const SizedBox(height: 16),

          // Thông báo
          if (_vm.successMessage != null && _vm.saving == false)
            _buildBanner(message: _vm.successMessage!, isSuccess: true),
          if (_vm.error != null && _vm.saving == false)
            _buildBanner(message: _vm.error!, isSuccess: false),
          const SizedBox(height: 8),

          // Nút Cập nhật
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _vm.saving ? null : _onUpdateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: _vm.saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(
                _vm.saving ? 'Đang lưu...' : 'Cập nhật thông tin',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Tab 2: Đổi mật khẩu
  // ──────────────────────────────────────────
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Đổi mật khẩu',
            icon: Icons.security,
            children: [
              _buildPasswordField(label: 'Mật khẩu hiện tại', controller: _oldPassCtrl, obscure: _obscureOld, onToggle: () => setState(() => _obscureOld = !_obscureOld)),
              _buildPasswordField(label: 'Mật khẩu mới', controller: _newPassCtrl, obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
              _buildPasswordField(label: 'Xác nhận mật khẩu mới', controller: _confirmPassCtrl, obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ],
          ),
          const SizedBox(height: 8),

          // Gợi ý mật khẩu mạnh
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mật khẩu phải có ít nhất 6 ký tự. Nên kết hợp chữ hoa, chữ thường và số.',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thông báo
          if (_vm.successMessage != null && _vm.saving == false && _tabController.index == 1)
            _buildBanner(message: _vm.successMessage!, isSuccess: true),
          if (_vm.error != null && _vm.saving == false && _tabController.index == 1)
            _buildBanner(message: _vm.error!, isSuccess: false),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _vm.saving ? null : _onChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: _vm.saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_reset, color: Colors.white),
              label: Text(
                _vm.saving ? 'Đang xử lý...' : 'Đổi mật khẩu',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Shared widgets
  // ──────────────────────────────────────────
  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary)),
          ]),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _accent, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: _accent, size: 20),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({required String message, required bool isSuccess}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSuccess ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: isSuccess ? Colors.green.shade800 : Colors.red.shade800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────
  Future<void> _onUpdateProfile() async {
    final success = await _vm.updateProfile(
      newName: _nameCtrl.text,
      newPhone: _phoneCtrl.text,
      newEmail: _emailCtrl.text,
      newAddress: _addressCtrl.text,
    );
    if (success && mounted) {
      _showSnack(_vm.successMessage!, isSuccess: true);
    } else if (!success && mounted) {
      _showSnack(_vm.error ?? 'Có lỗi xảy ra', isSuccess: false);
    }
  }

  Future<void> _onChangePassword() async {
    final oldPass = _oldPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ thông tin!', isSuccess: false);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Mật khẩu mới phải có ít nhất 6 ký tự!', isSuccess: false);
      return;
    }
    if (newPass != confirm) {
      _showSnack('Mật khẩu xác nhận không khớp!', isSuccess: false);
      return;
    }

    final success = await _vm.changePassword(oldPassword: oldPass, newPassword: newPass);
    if (mounted) {
      if (success) {
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSnack('Đổi mật khẩu thành công!', isSuccess: true);
      } else {
        _showSnack(_vm.error ?? 'Có lỗi xảy ra', isSuccess: false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn ảnh đại diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF1A237E), child: Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF3949AB), child: Icon(Icons.photo_library, color: Colors.white)),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 512);
      if (picked == null) return;
      final saved = await _vm.updateAvatar(picked.path);
      if (mounted) {
        _showSnack(saved ? 'Ảnh đại diện đã cập nhật!' : (_vm.error ?? 'Lỗi lưu ảnh'), isSuccess: saved);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Không chọn được ảnh: $e', isSuccess: false);
      }
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? Colors.green.shade700 : const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
