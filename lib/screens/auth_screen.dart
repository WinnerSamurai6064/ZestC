import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  final _regUser = TextEditingController();
  final _regName = TextEditingController();
  final _regPass = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscureLogin = true;
  bool _obscureReg = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginUser.text.isEmpty || _loginPass.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await ApiService().login(
      username: _loginUser.text.trim(),
      password: _loginPass.text,
    );
    setState(() => _loading = false);
    if (res['token'] != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _error = res['error'] ?? 'Login failed');
    }
  }

  Future<void> _register() async {
    if (_regUser.text.isEmpty || _regName.text.isEmpty || _regPass.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await ApiService().register(
      username: _regUser.text.trim(),
      displayName: _regName.text.trim(),
      password: _regPass.text,
    );
    setState(() => _loading = false);
    if (res['token'] != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _error = res['error'] ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ZestTheme.limeGreen.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ZestTheme.limeGreenDark.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [ZestTheme.limeGreen, ZestTheme.limeGreenDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ZestTheme.limeGreen.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ZestChat',
                    style: GoogleFonts.spaceGrotesk(
                      color: ZestTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Message with zest',
                    style: GoogleFonts.spaceGrotesk(
                      color: ZestTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: ZestTheme.glassCard(
                            opacity: 0.06, borderOpacity: 0.15, radius: 24),
                        child: Column(
                          children: [
                            // Tabs
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: ZestTheme.darkBase.withOpacity(0.6),
                              ),
                              child: TabBar(
                                controller: _tab,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [ZestTheme.limeGreen, ZestTheme.limeGreenDark],
                                  ),
                                ),
                                labelColor: ZestTheme.darkBase,
                                unselectedLabelColor: ZestTheme.textMuted,
                                labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Register'),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: _tab,
                                children: [_loginForm(), _registerForm()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.red.withOpacity(0.12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _loginUser,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: ZestTheme.limeGreen, size: 20),
              hintText: 'Username',
            ),
            style: const TextStyle(color: ZestTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loginPass,
            obscureText: _obscureLogin,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: ZestTheme.limeGreen, size: 20),
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLogin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ZestTheme.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
              ),
            ),
            style: const TextStyle(color: ZestTheme.textPrimary),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),
          ZestButton(label: 'Sign In', onTap: _login, loading: _loading),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _regName,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined, color: ZestTheme.limeGreen, size: 20),
              hintText: 'Display name',
            ),
            style: const TextStyle(color: ZestTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regUser,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.alternate_email, color: ZestTheme.limeGreen, size: 20),
              hintText: 'Username',
            ),
            style: const TextStyle(color: ZestTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPass,
            obscureText: _obscureReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: ZestTheme.limeGreen, size: 20),
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureReg ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ZestTheme.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              ),
            ),
            style: const TextStyle(color: ZestTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          ZestButton(label: 'Create Account', onTap: _register, loading: _loading),
        ],
      ),
    );
  }
}
