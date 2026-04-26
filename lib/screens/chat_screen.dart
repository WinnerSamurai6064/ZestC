import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/chat_provider.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final User otherUser;

  const ChatScreen({super.key, required this.chat, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _api = ApiService();
  bool _sending = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    provider.loadMessages(widget.chat.id);
    provider.startPolling(widget.chat.id);
  }

  @override
  void dispose() {
    context.read<ChatProvider>().stopPolling();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _sending = true);
    await context.read<ChatProvider>().sendMessage(
          chatId: widget.chat.id,
          content: text,
        );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploadingImage = true);
    final url = await _api.uploadImage(file.bytes!, file.name);
    setState(() => _uploadingImage = false);

    if (url != null && mounted) {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chat.id,
            imageUrl: url,
            content: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
          );
      _ctrl.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, provider, __) {
                final msgs = provider.messages[widget.chat.id] ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients &&
                      _scroll.position.maxScrollExtent > 0) {
                    final distFromBottom = _scroll.position.maxScrollExtent -
                        _scroll.position.pixels;
                    if (distFromBottom < 200) _scrollToBottom();
                  }
                });
                if (msgs.isEmpty) {
                  return _emptyChat();
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMine = msg.senderId == _api.currentUser?.id;
                    final showTime = i == msgs.length - 1 ||
                        msg.createdAt
                                .difference(msgs[i + 1].createdAt)
                                .abs()
                                .inMinutes >
                            3;
                    // Date separator
                    final showDate = i == 0 ||
                        !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) _dateSeparator(msg.createdAt),
                        MessageBubble(
                          message: msg,
                          isMine: isMine,
                          showTime: showTime,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          _InputBar(
            controller: _ctrl,
            onSend: _send,
            onPickImage: _pickAndSendImage,
            sending: _sending || _uploadingImage,
            uploadingImage: _uploadingImage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ZestTheme.darkSurface,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          ZestAvatar(user: widget.otherUser, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: ZestTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.otherUser.isOnline
                      ? 'Online'
                      : '@${widget.otherUser.username}',
                  style: TextStyle(
                    color: widget.otherUser.isOnline
                        ? ZestTheme.online
                        : ZestTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: ZestTheme.limeGreen),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: ZestTheme.limeGreen),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ZestTheme.darkBorder,
        ),
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZestAvatar(user: widget.otherUser, size: 72),
          const SizedBox(height: 16),
          Text(
            widget.otherUser.displayName,
            style: GoogleFonts.spaceGrotesk(
              color: ZestTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello! 👋',
            style: TextStyle(color: ZestTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _dateSeparator(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    String label;
    if (_sameDay(now, local)) {
      label = 'Today';
    } else if (_sameDay(now.subtract(const Duration(days: 1)), local)) {
      label = 'Yesterday';
    } else {
      label = '${local.day}/${local.month}/${local.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: ZestTheme.darkBorder, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(color: ZestTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: ZestTheme.darkBorder, thickness: 0.5)),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Input Bar ───────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final bool sending;
  final bool uploadingImage;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    required this.sending,
    required this.uploadingImage,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: ZestTheme.darkSurface,
        border: Border(top: BorderSide(color: ZestTheme.darkBorder)),
      ),
      child: Row(
        children: [
          // Attach
          GestureDetector(
            onTap: widget.uploadingImage ? null : widget.onPickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: ZestTheme.glassCard(radius: 12, borderOpacity: 0.15),
              child: widget.uploadingImage
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          color: ZestTheme.limeGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.attach_file_rounded,
                      color: ZestTheme.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: ZestTheme.darkCard,
                border: Border.all(color: ZestTheme.darkBorder),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: ZestTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: ZestTheme.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / mic
          GestureDetector(
            onTap: widget.sending ? null : widget.onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _hasText
                    ? const LinearGradient(
                        colors: [ZestTheme.limeGreen, ZestTheme.limeGreenDark])
                    : null,
                color: _hasText ? null : ZestTheme.darkCard,
                border: _hasText
                    ? null
                    : Border.all(color: ZestTheme.darkBorder),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: ZestTheme.limeGreen.withOpacity(0.35),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
              child: widget.sending
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: ZestTheme.darkBase,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                      color: _hasText ? ZestTheme.darkBase : ZestTheme.textMuted,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
