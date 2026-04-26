import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/chat_provider.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChats();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays == 0) return DateFormat('HH:mm').format(local);
    if (now.difference(local).inDays < 7) return DateFormat('EEE').format(local);
    return DateFormat('dd/MM').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final me = _api.currentUser;
    return Scaffold(
      body: Stack(
        children: [
          // Top glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  ZestTheme.limeGreen.withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'ZestChat',
                        style: GoogleFonts.spaceGrotesk(
                          color: ZestTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Search
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SearchScreen())),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: ZestTheme.glassCard(radius: 12, borderOpacity: 0.2),
                          child: const Icon(Icons.search_rounded,
                              color: ZestTheme.textPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: me != null
                            ? ZestAvatar(user: me, size: 38, showOnline: false)
                            : Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ZestTheme.darkCard),
                              ),
                      ),
                    ],
                  ),
                ),

                // Stories / active users row
                _StoriesRow(),

                const SizedBox(height: 8),

                // Chats label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Messages',
                        style: GoogleFonts.spaceGrotesk(
                          color: ZestTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Consumer<ChatProvider>(
                        builder: (_, p, __) {
                          final total = p.chats
                              .fold<int>(0, (s, c) => s + c.unreadCount);
                          if (total == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: ZestTheme.limeGreen,
                            ),
                            child: Text(
                              '$total',
                              style: TextStyle(
                                color: ZestTheme.darkBase,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Chat list
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (_, provider, __) {
                      if (provider.loadingChats && provider.chats.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: ZestTheme.limeGreen,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      if (provider.chats.isEmpty) {
                        return _emptyState();
                      }
                      return RefreshIndicator(
                        color: ZestTheme.limeGreen,
                        backgroundColor: ZestTheme.darkCard,
                        onRefresh: provider.loadChats,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: provider.chats.length,
                          itemBuilder: (_, i) {
                            final chat = provider.chats[i];
                            final other = chat.otherUser(me?.id ?? '');
                            final lastMsg = chat.lastMessage;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: GlassCard(
                                radius: 16,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chat: chat,
                                      otherUser: other,
                                    ),
                                  ),
                                ).then((_) => provider.loadChats()),
                                child: Row(
                                  children: [
                                    ZestAvatar(user: other, size: 48),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  other.displayName,
                                                  style: GoogleFonts.spaceGrotesk(
                                                    color: ZestTheme.textPrimary,
                                                    fontWeight: chat.unreadCount > 0
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    fontSize: 15,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(lastMsg?.createdAt),
                                                style: TextStyle(
                                                  color: chat.unreadCount > 0
                                                      ? ZestTheme.limeGreen
                                                      : ZestTheme.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: chat.unreadCount > 0
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  lastMsg?.isDeleted == true
                                                      ? 'Message deleted'
                                                      : lastMsg?.hasImage == true
                                                          ? '📷 Photo'
                                                          : lastMsg?.content ?? 'Start chatting',
                                                  style: TextStyle(
                                                    color: chat.unreadCount > 0
                                                        ? ZestTheme.textPrimary
                                                        : ZestTheme.textSecondary,
                                                    fontSize: 13,
                                                    fontStyle: lastMsg == null
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (chat.unreadCount > 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: ZestTheme.limeGreen,
                                                  ),
                                                  child: Text(
                                                    '${chat.unreadCount}',
                                                    style: TextStyle(
                                                      color: ZestTheme.darkBase,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        backgroundColor: ZestTheme.limeGreen,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ZestTheme.limeGreen.withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: ZestTheme.limeGreen.withOpacity(0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: GoogleFonts.spaceGrotesk(
              color: ZestTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ✏ to start a conversation',
            style: TextStyle(color: ZestTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Stories / Active users row ─────────────────────────────────
class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Decorative static row — can be extended to real stories
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ZestTheme.limeGreen.withOpacity(0.4),
                        width: 2,
                      ),
                      color: ZestTheme.darkCard,
                    ),
                    child: const Icon(Icons.add, color: ZestTheme.limeGreen, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your story',
                    style: TextStyle(color: ZestTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            );
          }
          final colors = [
            ZestTheme.limeGreen,
            ZestTheme.limeGreenDark,
            ZestTheme.limeAccent,
            ZestTheme.limeGreenDeep,
            Colors.tealAccent,
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors[(i - 1) % colors.length].withOpacity(0.8),
                        colors[i % colors.length].withOpacity(0.4),
                      ],
                    ),
                    border: Border.all(
                      color: colors[(i - 1) % colors.length].withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User $i',
                  style: TextStyle(color: ZestTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
