import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/chat_provider.dart';
import 'theme/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: ZestChatApp(isLoggedIn: api.currentUser != null),
    ),
  );
}

class ZestChatApp extends StatelessWidget {
  final bool isLoggedIn;
  const ZestChatApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZestChat',
      debugShowCheckedModeBanner: false,
      theme: ZestTheme.theme(),
      home: isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}
