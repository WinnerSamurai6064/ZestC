import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/chat_provider.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<User> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await ApiService().searchUsers(q.trim());
    setState(() { _results = res; _loading = false; });
  }

  Future<void> _openChat(User user) async {
    final chat = await context.read<ChatProvider>().openOrCreateChat(user.id);
    if (chat != null && mounted) {
      Navigator.pop(context); // Close search
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chat: chat, otherUser: user),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _search,
              style: const TextStyle(color: ZestTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search username...',
                prefixIcon: const Icon(Icons.search, color: ZestTheme.limeGreen, size: 20),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: ZestTheme.textMuted, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ZestTheme.limeGreen,
                      strokeWidth: 2,
                    ),
                  )
                : _results.isEmpty && _ctrl.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined,
                                color: ZestTheme.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No users found',
                              style: TextStyle(
                                  color: ZestTheme.textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final u = _results[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              radius: 14,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              onTap: () => _openChat(u),
                              child: Row(
                                children: [
                                  ZestAvatar(user: u, size: 46),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.displayName,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: ZestTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '@${u.username}',
                                          style: const TextStyle(
                                            color: ZestTheme.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: ZestTheme.limeGreen.withOpacity(0.15),
                                      border: Border.all(
                                          color: ZestTheme.limeGreen.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Message',
                                      style: TextStyle(
                                        color: ZestTheme.limeGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
