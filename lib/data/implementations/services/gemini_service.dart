import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../domain/entities/meal_suggestion.dart';

class GeminiService {
  // Chỉ dùng OPENAI_API_KEY
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static String get _endpoint => 'https://api.openai.com/v1/chat/completions';

  static Future<String> suggestMeals(List<String> ingredients) async {
    final prompt = ingredients.isEmpty
        ? 'Gợi ý 3 món ăn Việt Nam ngon, đơn giản cho bữa ăn gia đình hôm nay. '
              'Với mỗi món hãy ghi tên và một câu mô tả ngắn gọn.'
        : 'Tôi có các nguyên liệu sau: ${ingredients.join(", ")}. '
              'Hãy gợi ý 3 món ăn Việt Nam ngon. '
              'Với mỗi món hãy ghi tên và một câu mô tả ngắn gọn. '
              'Trả lời bằng tiếng Việt, ngắn gọn.';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một trợ lý ảo tư vấn nấu ăn Việt Nam chuyên nghiệp.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': 0.7,
      'max_tokens': 400,
    });

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            final text = data['choices'][0]['message']['content'];
            return text?.trim() ?? 'Không nhận được phản hồi từ AI';
          }
          throw Exception('Cấu trúc dữ liệu không đúng');
        }

        if (response.statusCode == 429) {
          // Rate limit: chờ 2 giây rồi thử lại
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          throw Exception(
            'API đang quá tải (429). Vui lòng thử lại sau vài giây.',
          );
        }

        print('OpenAI error ${response.statusCode}: ${response.body}');
        throw Exception('OpenAI API lỗi ${response.statusCode}');
      } on TimeoutException {
        throw Exception('Hết thời gian chờ. Kiểm tra kết nối mạng.');
      } catch (e) {
        if (e.toString().contains('429') || e.toString().contains('quá tải')) {
          rethrow;
        }
        throw Exception('Lỗi kết nối: $e');
      }
    }

    throw Exception('Không thể kết nối tới AI. Thử lại sau.');
  }

  /// Phân nhóm [items] vào từng cửa hàng phù hợp trong [storeNames]
  /// Trả về Map<storeName, List<itemName>>
  static Future<Map<String, List<String>>> assignItemsToStores({
    required List<String> items,
    required List<String> storeNames,
  }) async {
    if (items.isEmpty || storeNames.isEmpty) return {};

    final prompt = '''
Tôi có danh sách cần mua: ${items.join(', ')}.
Gần tôi có các cửa hàng: ${storeNames.join(', ')}.
Hãy phân nhóm các món cần mua vào cửa hàng phù hợp nhất (dựa vào loại hàng hóa thường bán ở mỗi loại cửa hàng).
Mỗi món chỉ xuất hiện ở 1 cửa hàng.
Trả về đúng định dạng JSON như sau (không thêm gì khác, không markdown):
{"TênCửaHàng1": ["item1", "item2"], "TênCửaHàng2": ["item3"]}
Chỉ trả về JSON thuần túy.''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một trợ lý thông minh chỉ trả về format JSON theo yêu cầu mà không có code block markdown nha.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': 0.3,
      'max_tokens': 500,
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('OpenAI API lỗi ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] ?? '';

      // Tẩy markdown codeblock đi nếu AI có lỡ thêm `json 
      String cleanText = text.replaceAll('```json', '').replaceAll('```', '');
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanText);
      if (jsonMatch == null) throw Exception('Không parse được JSON từ AI. Raw: $text');

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return parsed.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
    } catch (e) {
      throw Exception('Lỗi phân nhóm AI: $e');
    }
  }

  /// Gợi ý nội dung món ăn ngày Tết & nguyên liệu dựa trên tiêu đề và nhóm
  static Future<String> suggestTemplateContent({
    required String title,
    required String category,
  }) async {
    final prompt = '''
Người dùng đang tạo một danh sách mua sắm/thực đơn mới.
Tiêu đề danh sách: "$title".
Nhóm danh sách: "$category".
Hãy gợi ý danh sách các món ăn hoặc hàng hoá phù hợp (đặc biệt ưu tiên món ăn ngày Tết nếu nhóm/tiêu đề có liên quan).

BẮT BUỘC trả về ĐÚNG MỘT ARRAY JSON theo định dạng sau (không giải thích thêm, không có code block markdown):
[
  {
    "name": "Tên món ăn 1",
    "description": "Thành phần và định lượng"
  },
  {
    "name": "Tên món ăn 2",
    "description": "Thành phần và định lượng"
  }
]
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một trợ lý thông minh chỉ xuất dữ liệu dạng JSON Array thuần.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': 0.7,
      'max_tokens': 800,
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('OpenAI API lỗi ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] ?? '';
      
      String cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return cleanText;
    } catch (e) {
      throw Exception('Lỗi AI gợi ý: $e');
    }
  }

  /// Gợi ý món ăn có cấu trúc JSON, trả về danh sách [MealSuggestion]
  static Future<List<MealSuggestion>> suggestMealsStructured(
      List<String> ingredients) async {
    final ingredientPart = ingredients.isEmpty
        ? ''
        : 'Tôi có sẵn các nguyên liệu: ${ingredients.join(", ")}.';

    final prompt = '''
Gợi ý 3 món ăn truyền thống ngày Tết Việt Nam đặc sắc. $ingredientPart
Với mỗi món, hãy liệt kê các nguyên liệu chính cần mua kèm định lượng và đơn vị (không bao gồm gia vị cơ bản như muối, đường, dầu ăn).

BẮT BUỘC trả về ĐÚNG MỘT JSON ARRAY theo định dạng sau (không giải thích thêm, không có code block markdown):
[
  {
    "id": "TET001",
    "name": "Tên món ăn",
    "description": "Mô tả ngắn gọn 1 câu về ý nghĩa hoặc đặc trưng của món này",
    "category": "Nhóm món (ví dụ: Món gói, Món nguội, Món chiên, Món hầm, Món luộc)",
    "main_ingredients": [
      {"item": "Tên nguyên liệu", "quantity": "500", "unit": "g"},
      {"item": "Tên nguyên liệu 2", "quantity": "1", "unit": "kg"}
    ]
  }
]
Trả lời bằng tiếng Việt.''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              'Bạn là trợ lý ảo tư vấn nấu ăn. Chỉ trả về JSON thuần, không markdown.',
        },
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
      'max_tokens': 1500,
    });

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String text = data['choices']?[0]?['message']?['content'] ?? '';
          text = text
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

          final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
          if (arrayMatch == null) {
            throw Exception('Không parse được JSON từ AI.');
          }

          final parsed = jsonDecode(arrayMatch.group(0)!) as List<dynamic>;
          return parsed
              .map((e) => MealSuggestion.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        if (response.statusCode == 429 && attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        throw Exception('OpenAI API lỗi ${response.statusCode}');
      } on TimeoutException {
        throw Exception('Hết thời gian chờ. Kiểm tra kết nối mạng.');
      } catch (e) {
        if (attempt == 1) { rethrow; }
        if (!e.toString().contains('429') &&
            !e.toString().contains('quá tải')) {
          rethrow;
        }
      }
    }

    throw Exception('Không thể kết nối tới AI. Thử lại sau.');
  }

  /// Gợi ý giá tiền (VNĐ) của một món hàng dựa trên tên (và danh mục)
  static Future<double> suggestPrice({
    required String itemName,
    required String category,
  }) async {
    final prompt = '''
Bạn là một chuyên gia về giá cả thị trường tại Việt Nam.
Tôi muốn mua món hàng: "$itemName" thuộc danh mục: "$category".
Hãy gợi ý mức giá trung bình hoặc phổ biến nhất (đơn vị VNĐ) cho 1 đơn vị tính thông thường của món này ở thời điểm hiện tại.
BẮT BUỘC trả về CHỈ MỘT CON SỐ DUY NHẤT (không có dấu phẩy hay dấu chấm phân cách hàng nghìn, không có chữ VNĐ, không giải thích). 
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một hệ thống chỉ xuất ra một con số duy nhất.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': 0.1, // Thấp để lấy kết quả nhất quán
      'max_tokens': 10,
    });

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content'] ?? '';
          
          // Làm sạch chuỗi
          String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanText.isEmpty) {
            throw Exception('AI không trả về giá hợp lệ');
          }
          return double.parse(cleanText);
        }

        if (response.statusCode == 429 && attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        throw Exception('OpenAI API lỗi ${response.statusCode}');
      } on TimeoutException {
        throw Exception('Hết thời gian chờ. Kiểm tra kết nối mạng.');
      } catch (e) {
        if (attempt == 1) rethrow;
      }
    }
    throw Exception('Không thể kết nối tới AI. Thử lại sau.');
  }
}
