import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/implementations/services/maps_service.dart';
import '../../data/implementations/services/gemini_service.dart';
import '../../domain/entities/shopping_item.dart';

class ShoppingRoutePage extends StatefulWidget {
  final List<ShoppingItem> items;
  const ShoppingRoutePage({super.key, required this.items});

  @override
  State<ShoppingRoutePage> createState() => _ShoppingRoutePageState();
}

class _ShoppingRoutePageState extends State<ShoppingRoutePage> {
  static const Color _red = Color(0xFFB71C1C);

  // ── Bán kính tìm kiếm ──
  static const List<int> _radiusOptions = [2000, 5000, 10000];
  int _selectedRadius = 2000; // mặc định 2km

  // ── State ──
  String _step = '';
  bool _loading = true;
  String? _error;
  Position? _userPosition;

  List<NearbyStore> _stores = [];
  Map<String, List<String>> _assignment = {}; // storeName → items

  @override
  void initState() {
    super.initState();
    _buildRoute();
  }

  Future<void> _buildRoute() async {
    setState(() { _loading = true; _error = null; });

    try {
      // ── 1. Lấy vị trí ──
      setState(() => _step = '📍 Đang lấy vị trí của bạn...');
      final position = await _getLocation();
      _userPosition = position;

      // ── 2. Tìm cửa hàng gần ──
      setState(() => _step = '🏪 Đang tìm cửa hàng gần đây...');
      _stores = await MapsService.getNearbyStores(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: _selectedRadius,
      );

      if (_stores.isEmpty) {
        final km = (_selectedRadius / 1000).toStringAsFixed(0);
        setState(() { _loading = false; _error = 'Không tìm thấy cửa hàng nào trong bán kính ${km}km. Thử tăng bán kính tìm kiếm.'; });
        return;
      }

      // ── 3. Tính khoảng cách ──
      setState(() => _step = '📏 Đang tính khoảng cách...');
      await MapsService.fillDistances(
        userLat: position.latitude,
        userLng: position.longitude,
        stores: _stores,
      );

      // ── 4. Gemini phân nhóm ──
      setState(() => _step = '🤖 AI đang phân nhóm danh sách mua sắm...');
      final itemNames = widget.items.map((i) => i.name).toList();
      final storeNames = _stores.map((s) => s.name).toList();
      _assignment = await GeminiService.assignItemsToStores(
        items: itemNames,
        storeNames: storeNames,
      );

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Dịch vụ vị trí đang tắt. Vui lòng bật GPS.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Bạn đã từ chối quyền truy cập vị trí.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí bị từ chối vĩnh viễn. Vào Cài đặt để cấp quyền.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _openMaps(NearbyStore store) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${store.lat},${store.lng}',
    );
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success) {
        debugPrint('Không thể mở bản đồ');
      }
    } catch (e) {
      debugPrint('Lỗi mở bản đồ: $e');
    }
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text('🗺️ Lộ trình mua sắm', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _buildRoute,
              tooltip: 'Tải lại',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildRadiusSelector(),
        ),
      ),
      body: _loading
          ? _buildLoadingView()
          : _error != null
          ? _buildErrorView()
          : _buildResultView(),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      color: _red,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📍 Bán kính:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          ..._radiusOptions.map((r) {
            final isSelected = r == _selectedRadius;
            final label = '${(r / 1000).toStringAsFixed(0)}km';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  if (r != _selectedRadius) {
                    setState(() => _selectedRadius = r);
                    _buildRoute();
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: isSelected ? _red : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? Colors.white : Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFB71C1C), strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              _step,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _buildRoute,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    // Lọc chỉ store nào có item được phân công
    final assignedStores = _stores
        .where((s) => (_assignment[s.name]?.isNotEmpty ?? false))
        .toList();

    // Item chưa được phân công vào đâu
    final allAssigned = _assignment.values.expand((e) => e).toSet();
    final unassigned = widget.items
        .map((i) => i.name)
        .where((n) => !allAssigned.contains(n))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_userPosition != null) _buildMapView(assignedStores),
        const SizedBox(height: 16),
        // ── Tóm tắt ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Color(0xFFB71C1C)),
              const SizedBox(width: 10),
              Text(
                '${widget.items.length} món cần mua • ${assignedStores.length} cửa hàng',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Danh sách cửa hàng theo thứ tự gần → xa ──
        ...assignedStores.asMap().entries.map((entry) {
          final idx = entry.key;
          final store = entry.value;
          final storeItems = _assignment[store.name] ?? [];

          return _buildStoreCard(
            index: idx + 1,
            store: store,
            items: storeItems,
          );
        }),

        // ── Item chưa phân nhóm (nếu có) ──
        if (unassigned.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Chưa xác định cửa hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...unassigned.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $item', style: const TextStyle(fontSize: 13)),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStoreCard({
    required int index,
    required NearbyStore store,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // ── Header cửa hàng ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                        ),
                      ),
                      if (store.address.isNotEmpty)
                        Text(
                          store.address,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDistance(store.distanceMeters),
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
                      ),
                    ),
                    const Text('cách đây', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // ── Danh sách item ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      Text(item, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(store),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Mở Bản Đồ', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: Color(0xFFB71C1C)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(List<NearbyStore> assignedStores) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.buy_management_project',
          ),
          MarkerLayer(
            markers: [
              // User Marker
              Marker(
                point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                width: 40,
                height: 40,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
              ),
              // Store Markers
              ...assignedStores.map((store) {
                return Marker(
                  point: LatLng(store.lat, store.lng),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Color(0xFFB71C1C), size: 36),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
