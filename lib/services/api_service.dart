import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api',
  );

  String? _token;
  User? currentUser;

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      currentUser = User.fromJson(jsonDecode(userJson));
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> _saveSession(String token, User user) async {
    _token = token;
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  // AUTH
  Future<Map<String, dynamic>> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'display_name': displayName,
        'password': password,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['token'] != null) {
      await _saveSession(data['token'], User.fromJson(data['user']));
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      await _saveSession(data['token'], User.fromJson(data['user']));
    }
    return data;
  }

  // USERS
  Future<List<User>> searchUsers(String query) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((u) => User.fromJson(u)).toList();
    }
    return [];
  }

  // CHATS
  Future<List<Chat>> getChats() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/chats'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((c) => Chat.fromJson(c, currentUser!.id)).toList();
    }
    return [];
  }

  Future<Chat?> createOrGetChat(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chats'),
      headers: _headers,
      body: jsonEncode({'participant_id': userId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Chat.fromJson(jsonDecode(res.body), currentUser!.id);
    }
    return null;
  }

  // MESSAGES
  Future<List<Message>> getMessages(String chatId, {int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/chats/$chatId/messages?page=$page&limit=50'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((m) => Message.fromJson(m)).toList();
    }
    return [];
  }

  Future<Message?> sendMessage({
    required String chatId,
    String? content,
    String? imageUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chats/$chatId/messages'),
      headers: _headers,
      body: jsonEncode({
        if (content != null) 'content': content,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );
    if (res.statusCode == 201) {
      return Message.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<String?> uploadImage(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['url'];
    }
    return null;
  }

  Future<void> markRead(String chatId) async {
    await http.patch(
      Uri.parse('$_baseUrl/chats/$chatId/read'),
      headers: _headers,
    );
  }

  Future<User?> updateProfile({String? displayName, String? bio, String? avatarUrl}) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    );
    if (res.statusCode == 200) {
      final user = User.fromJson(jsonDecode(res.body));
      currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
      return user;
    }
    return null;
  }
}
