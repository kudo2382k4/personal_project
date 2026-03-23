import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Thông tin một cửa hàng gần đó
class NearbyStore {
  final String name;
  final String address;
  final String placeId;
  final double lat;
  final double lng;
  int distanceMeters; 

  NearbyStore({
    required this.name,
    required this.address,
    required this.placeId,
    required this.lat,
    required this.lng,
    this.distanceMeters = 0,
  });
}

class MapsService {
  /// Tìm siêu thị / chợ gần vị trí [lat],[lng] trong bán kính [radiusMeters]
  static Future<List<NearbyStore>> getNearbyStores({
    required double lat,
    required double lng,
    int radiusMeters = 2000,
  }) async {
    final query = '''
      [out:json][timeout:10];
      (
        node["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
        way["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
        relation["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
        
        node["shop"="convenience"](around:$radiusMeters,$lat,$lng);
        way["shop"="convenience"](around:$radiusMeters,$lat,$lng);
        relation["shop"="convenience"](around:$radiusMeters,$lat,$lng);
        
        node["amenity"="marketplace"](around:$radiusMeters,$lat,$lng);
        way["amenity"="marketplace"](around:$radiusMeters,$lat,$lng);
        relation["amenity"="marketplace"](around:$radiusMeters,$lat,$lng);
      );
      out center;
    ''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http.post(url, body: query).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Overpass API lỗi ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final elements = data['elements'] as List? ?? [];

    // Chỉ lấy những cửa hàng có tên để tránh hiển thị "Không rõ tên" quá nhiều
    final validElements = elements.where((el) => el['tags']?['name'] != null).toList();

    return validElements.take(8).map((el) {
      final tags = el['tags'] ?? {};
      final name = tags['name'] ?? 'Không rõ tên';
      final isNode = el['type'] == 'node';
      final elLat = isNode ? el['lat'] : el['center']['lat'];
      final elLng = isNode ? el['lon'] : el['center']['lon'];
      
      // Tập hợp địa chỉ nếu có
      String address = '';
      if (tags['addr:street'] != null) {
        address = '${tags['addr:housenumber'] ?? ''} ${tags['addr:street']}'.trim();
      }
      
      return NearbyStore(
        name: name,
        address: address,
        placeId: el['id'].toString(),
        lat: (elLat as num).toDouble(),
        lng: (elLng as num).toDouble(),
      );
    }).toList();
  }

  /// Tính khoảng cách từ [userLat],[userLng] đến từng cửa hàng 
  /// bằng đường chim bay bằng Geolocator
  static Future<void> fillDistances({
    required double userLat,
    required double userLng,
    required List<NearbyStore> stores,
  }) async {
    if (stores.isEmpty) return;

    for (var store in stores) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        store.lat,
        store.lng,
      );
      store.distanceMeters = distance.toInt();
    }

    // Sắp xếp gần → xa
    stores.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }
}
