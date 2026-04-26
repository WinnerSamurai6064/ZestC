import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Chat> chats = [];
  Map<String, List<Message>> messages = {};
  bool loadingChats = false;
  String? error;

  // Polling timer (fallback when no WebSocket)
  Timer? _pollTimer;
  String? _activeChatId;

  Future<void> loadChats() async {
    loadingChats = true;
    notifyListeners();
    try {
      chats = await _api.getChats();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loadingChats = false;
    notifyListeners();
  }

  Future<void> loadMessages(String chatId) async {
    try {
      final msgs = await _api.getMessages(chatId);
      messages[chatId] = msgs;
      notifyListeners();
      await _api.markRead(chatId);
      // Clear unread badge
      final idx = chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        final c = chats[idx];
        chats[idx] = Chat(
          id: c.id,
          participants: c.participants,
          lastMessage: c.lastMessage,
          unreadCount: 0,
          updatedAt: c.updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
    }
  }

  void startPolling(String chatId) {
    _activeChatId = chatId;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_activeChatId == chatId) {
        final msgs = await _api.getMessages(chatId);
        final current = messages[chatId] ?? [];
        if (msgs.length != current.length) {
          messages[chatId] = msgs;
          notifyListeners();
        }
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _activeChatId = null;
  }

  Future<bool> sendMessage({
    required String chatId,
    String? content,
    String? imageUrl,
  }) async {
    // Optimistic add
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = Message(
      id: tempId,
      chatId: chatId,
      senderId: _api.currentUser!.id,
      content: content,
      imageUrl: imageUrl,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    messages[chatId] = [...(messages[chatId] ?? []), tempMsg];
    notifyListeners();

    final msg = await _api.sendMessage(
      chatId: chatId,
      content: content,
      imageUrl: imageUrl,
    );

    if (msg != null) {
      final list = messages[chatId] ?? [];
      final idx = list.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        list[idx] = msg;
        messages[chatId] = list;
      }
      // Update last message in chat list
      final ci = chats.indexWhere((c) => c.id == chatId);
      if (ci != -1) {
        final c = chats[ci];
        chats[ci] = Chat(
          id: c.id,
          participants: c.participants,
          lastMessage: msg,
          unreadCount: 0,
          updatedAt: msg.createdAt,
        );
      }
      notifyListeners();
      return true;
    }
    // Remove optimistic on failure
    messages[chatId]?.removeWhere((m) => m.id == tempId);
    notifyListeners();
    return false;
  }

  Future<Chat?> openOrCreateChat(String userId) async {
    final chat = await _api.createOrGetChat(userId);
    if (chat != null) {
      final idx = chats.indexWhere((c) => c.id == chat.id);
      if (idx == -1) chats.insert(0, chat);
      notifyListeners();
    }
    return chat;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
