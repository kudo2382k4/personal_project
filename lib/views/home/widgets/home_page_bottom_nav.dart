import 'package:flutter/material.dart';

class HomePageBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const HomePageBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFFB71C1C);
  static const Color _inactiveColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Tổng quan'),
              _buildNavItem(index: 1, icon: Icons.shopping_bag_outlined, label: 'Danh sách'),
              _buildNavItem(index: 2, icon: Icons.card_giftcard_outlined, label: 'Ngân sách'),
              // _buildNavItem(index: 3, icon: Icons.map_outlined, label: 'Lộ trình'),
              _buildNavItem(index: 4, icon: Icons.bar_chart_rounded, label: 'Cá nhân'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? _activeColor : _inactiveColor,
            size: 26,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _activeColor : _inactiveColor,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
