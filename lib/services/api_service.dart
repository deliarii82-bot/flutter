import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> headers({bool withAuth = true}) async {
    final result = <String, String>{'Accept': 'application/json'};

    if (withAuth) {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        result['Authorization'] = 'Bearer $token';
      }
    }

    return result;
  }

  static dynamic decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server bukan JSON yang valid.');
    }
  }

  static String getMessage(dynamic data) {
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? 'Terjadi kesalahan.')
          .toString();
    }

    return 'Terjadi kesalahan pada server.';
  }

  static void checkResponse(http.Response response, dynamic data) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(getMessage(data));
    }

    if (data is Map && data['success'] == false) {
      throw Exception(getMessage(data));
    }
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
    );

    final data = decodeResponse(response);
    checkResponse(response, data);

    return data;
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        ...await headers(withAuth: withAuth),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = decodeResponse(response);
    checkResponse(response, data);

    return data;
  }

  static dynamic unwrap(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }

    return data;
  }

  // LOGIN
  static Future<dynamic> login(String email, String password) async {
    final result = await post('/login', {
      'email': email,
      'password': password,
    }, withAuth: false);

    final data = unwrap(result);

    if (data is Map) {
      final token =
          data['token'] ??
          data['access_token'] ??
          (data['user'] is Map ? data['user']['token'] : null);

      if (token != null && token.toString().isNotEmpty) {
        await saveToken(token.toString());
      }
    }

    return result;
  }

  // REGISTER
  static Future<dynamic> register(
    String name,
    String email,
    String phone,
    String gender,
  ) async {
    String shortGender = (gender.toLowerCase().contains('laki')) ? 'L' : 'P';

    return post('/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'no_telp': phone,
      'gender': shortGender,
      'jenis_kelamin': shortGender,
      'password': 'password123',
      'password_confirmation': 'password123',
    }, withAuth: false);
  }

  // DASHBOARD
  static Future<dynamic> getDashboard() async {
    return get('/dashboard');
  }

  // DAFTAR SURVEY
  static Future<dynamic> getSurveys() async {
    return get('/surveys');
  }

  // KATEGORI SURVEY
  static Future<dynamic> getCategories() async {
    return get('/categories');
  }

  // DETAIL SURVEY
  static Future<dynamic> getSurvey(int id) async {
    return get('/surveys/$id');
  }

  // SIMPAN ATAU EDIT SURVEY (Mendukung File Mobile & Bytes Web)
  static Future<dynamic> saveSurvey({
    int? id,
    required String title,
    required int categoryId,
    required String description,
    required String latitude,
    required String longitude,
    File? photoFile,
    Uint8List? photoBytes,
  }) async {
    final token = await getToken();

    final String endpoint = id != null ? '/surveys/$id' : '/surveys/save';
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );

    request.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['category_id'] = categoryId.toString();
    request.fields['description'] = description;
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;

    if (id != null) {
      request.fields['_method'] = 'PUT';
    }

    // Tangani Foto untuk Mobile (File)
    if (photoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
    } 
    // Tangani Foto untuk Web (Uint8List Bytes)
    else if (photoBytes != null && photoBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: 'survey_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = decodeResponse(response);
    checkResponse(response, data);

    return data;
  }

  // HAPUS SURVEY
  static Future<dynamic> deleteSurvey(int id) async {
    return post('/surveys/$id/delete', {});
  }

  // PROFIL
  static Future<dynamic> getProfile() async {
    return get('/profile');
  }

  

  static Future<dynamic> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    return post('/profile/update', {
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
    });
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      await post('/logout', {});
    } finally {
      await clearToken();
    }
  }
}