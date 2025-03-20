import 'package:crypto_navigator/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'screens/home_screen.dart';
import 'providers/favorites_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: CryptoApp(),
    ),
  );
}

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Tracker',
      theme: ThemeData.dark(),
      home: LoginScreen(),
    );
  }
}
