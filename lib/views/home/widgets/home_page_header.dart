import 'package:flutter/material.dart';

class HomePageHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onSettingsTap;
  const HomePageHeader({super.key, required this.userName, required this.onSettingsTap});

  static const Color _red = Color(0xFFB71C1C);
  static const Color _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _red,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          // ── Logo tròn ──
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 2),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          // ── Chữ chào + subtitle ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chúc mừng năm mới! Mã đão thành công 🎉',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Icon cài đặt ──
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
