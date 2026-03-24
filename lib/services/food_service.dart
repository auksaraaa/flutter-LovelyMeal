// lib/services/food_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/user_preferences.dart';

class FoodService {
  static const String baseUrl = "https://5d21-35-232-220-151.ngrok-free.app";

  static Future<Map<String, dynamic>> search({
    required String query,
    required UserPreferences preferences,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/search"),
            headers: {
              "Content-Type": "application/json",
              "ngrok-skip-browser-warning": "true",
            },
            body: jsonEncode({
              "query": query,
              "allergies": preferences.allergies,
              "disliked": preferences.disliked,
              "liked": preferences.liked,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawResults = data['results'];
        return {
          "status": data['status'],
          "message": data['message'],
          "results": (rawResults is List ? rawResults : <dynamic>[])
              .map((item) => FoodItem.fromJson(item))
              .toList(),
        };
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception(
          'API Error ${response.statusCode}: '
          '${errorBody.isNotEmpty ? errorBody : 'No response body'}',
        );
      }
    } on SocketException catch (e) {
      throw Exception('เชื่อมต่อเครือข่ายไม่ได้: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP ผิดพลาด: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('รูปแบบข้อมูลจาก API ไม่ถูกต้อง: ${e.message}');
    } catch (e) {
      throw Exception('เชื่อมต่อ API ไม่ได้: $e');
    }
  }
}
