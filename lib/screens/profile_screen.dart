import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = _api.currentUser;
    _nameCtrl.text = u?.displayName ?? '';
    _bioCtrl.text = u?.bio ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _api.updateProfile(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    setState(() { _saving = false; _editing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: ZestTheme.limeGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _api.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(
              _editing ? 'Cancel' : 'Edit',
              style: TextStyle(color: ZestTheme.limeGreen, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [ZestTheme.limeGreen, ZestTheme.limeGreenDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ZestTheme.limeGreen.withOpacity(0.35),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(
                        u?.displayName.isNotEmpty == true
                            ? u!.displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.spaceGrotesk(
                          color: ZestTheme.darkBase,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_editing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ZestTheme.limeGreen,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Fields
            GlassCard(
              radius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _field('Display Name', _nameCtrl, _editing,
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _field('Username', TextEditingController(text: u?.username),
                      false, icon: Icons.alternate_email),
                  const SizedBox(height: 16),
                  _field('Bio', _bioCtrl, _editing,
                      icon: Icons.info_outline, maxLines: 3),
                ],
              ),
            ),

            if (_editing) ...[
              const SizedBox(height: 20),
              ZestButton(label: 'Save Changes', onTap: _save, loading: _saving),
            ],

            const SizedBox(height: 32),

            // Stats row
            GlassCard(
              radius: 18,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Joined', 'Today'),
                  _divider(),
                  _stat('Status', u?.isOnline == true ? 'Online' : 'Offline'),
                  _divider(),
                  _stat('Messages', '—'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout
            ZestButton(
              label: 'Sign Out',
              outline: true,
              icon: Icons.logout_rounded,
              onTap: () async {
                await _api.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool editable,
      {IconData? icon, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: ZestTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        if (editable)
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(color: ZestTheme.textPrimary),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: ZestTheme.limeGreen, size: 18)
                  : null,
            ),
          )
        else
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: ZestTheme.textMuted, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  ctrl.text.isEmpty ? '—' : ctrl.text,
                  style: const TextStyle(
                    color: ZestTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: ZestTheme.limeGreen,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: ZestTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: ZestTheme.darkBorder);
}
