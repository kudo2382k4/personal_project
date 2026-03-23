import 'package:flutter/material.dart';
import '../../di.dart';
import '../../viewmodels/shopping/shopping_viewmodel.dart';
import 'widgets/home_page_header.dart';
import 'widgets/home_page_body.dart';
import 'widgets/home_page_bottom_nav.dart';
import '../auth/login_page.dart';
import '../shopping/shopping_list_page.dart';
import '../budget/budget_page.dart';
import '../profile/profile_page.dart';
import '../../data/implementations/services/background_music_service.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final int userId;
  const HomePage({super.key, required this.userName, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final _logoutVM = buildLoginVM();
  final _refreshTicker = ValueNotifier<int>(0);
  late final ShoppingViewmodel _shoppingVm;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Tạo một ViewModel duy nhất được dùng chung bởi HomePageBody và ShoppingListPage
    _shoppingVm = buildShoppingVM(widget.userId)
      ..loadItems();
    _pages = [
      HomePageBody(
        userId: widget.userId,
        onNavigateToBudget: () => setState(() => _selectedIndex = 2),
        refreshTicker: _refreshTicker,
        sharedVm: _shoppingVm,
      ),
      ShoppingListPage(userId: widget.userId, sharedVm: _shoppingVm),
      BudgetPage(userId: widget.userId),
      const Center(child: Text('Lịch trình', style: TextStyle(fontSize: 22, color: Colors.grey))),
      ProfilePage(userId: widget.userId, userName: widget.userName),
    ];
  }

  @override
  void dispose() {
    _refreshTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        children: [
          // ── Header (Hiển thị ở mọi tab) ──
          HomePageHeader(
            userName: widget.userName,
            onSettingsTap: () => _showSettingsSheet(),
          ),

          // ── Body cuộn ──
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomePageBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          // Khi quay về tab Home từ tab khác → reload data
          if (index == 0 && _selectedIndex != 0) {
            _refreshTicker.value++;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final music = BackgroundMusicService.instance;
          final track = music.currentTrack;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── Nhạc nền ──
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: music.isPlaying
                          ? Colors.purple.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      music.isPlaying ? Icons.music_note : Icons.music_off,
                      color: music.isPlaying
                          ? const Color(0xFF6A1B9A)
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    music.isPlaying ? 'Tắt nhạc nền' : 'Bật nhạc nền',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: music.errorMessage != null
                      ? Text(
                          music.errorMessage!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.redAccent),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : (track != null && music.isPlaying
                          ? Text(
                              '🎵 ${track.title}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.purple),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text('Nhạc Tết vui tươi',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey))),
                  trailing: Switch(
                    value: music.isPlaying,
                    activeColor: const Color(0xFF6A1B9A),
                    onChanged: (_) async {
                      await music.toggle();
                      setSheetState(() {});
                    },
                  ),
                  onTap: () async {
                    await music.toggle();
                    setSheetState(() {});
                  },
                ),
                const Divider(),

                // ── Đăng xuất ──
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, color: Color(0xFFB71C1C)),
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFFB71C1C)),
                  ),
                  subtitle: const Text('Thoát và quay về trang đăng nhập'),
                  onTap: () => _confirmLogout(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }


  void _confirmLogout() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Đăng xuất?'),
            content: const Text('Bạn có chắc muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logoutVM.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                    'Đăng xuất', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
