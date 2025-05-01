// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:crypto_navigator/providers/portfolio_provider.dart';
import 'package:crypto_navigator/screens/news_screen.dart';
import 'package:crypto_navigator/screens/reset_password_screen.dart';
import 'package:crypto_navigator/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/favorites_provider.dart';
import 'screens/crypto_list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tqhbjyvsztxqzzlcwgxn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxaGJqeXZzenR4cXp6bGN3Z3huIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0ODc4MDIsImV4cCI6MjA1ODA2MzgwMn0.CvngCQXkwSjRjBzOxk1wZYl4Y-nYGdfVe8RUIc2zUvE',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ChangeNotifierProvider(create: (context) => PortfolioProvider()),
      ],
      child: CryptoApp(),
    ),
  );
}

// Application theme configuration with the new color palette
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF0D47A1), // Deep Blue
  scaffoldBackgroundColor: const Color(0xFF121212), // Almost Black
  cardColor: const Color(0xFF1F1F1F), // Card Backgrounds
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF0D47A1), // Deep Blue
    secondary: Color(0xFF03DAC6), // Teal/Aqua
    surface: Color(0xFF1F1F1F), // Card Backgrounds
    background: Color(0xFF121212), // Almost Black
    error: Color(0xFFFF5252), // Bright Red
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: Colors.white, // Text Color
    displayColor: Colors.white, // Text Color
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D47A1), // Deep Blue
    foregroundColor: Colors.white, // Text Color
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color(0xFF03DAC6), // Teal/Aqua
    unselectedItemColor: Colors.white70, // Slightly transparent white
    backgroundColor: Color(0xFF0D47A1), // Deep Blue
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  cardTheme: CardTheme(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0D47A1), // Deep Blue
      foregroundColor: Colors.white, // Text Color
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1F1F1F), // Card Backgrounds
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: Color(0xFF03DAC6), width: 2), // Teal/Aqua
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF03DAC6), // Teal/Aqua
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF0D47A1); // Deep Blue
      }
      return null;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF03DAC6); // Teal/Aqua
      }
      return Colors.grey;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF03DAC6)
            .withOpacity(0.5); // Teal/Aqua with opacity
      }
      return Colors.grey.withOpacity(0.5);
    }),
  ),
);

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Navigator',
      theme: appTheme,
      home: LoadingScreen(),
      routes: {
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => CryptoApp(),
        '/reset-password': (context) => ResetPasswordScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          return session != null ? HomeScreen() : LoginScreen();
        }

        final primaryColor = const Color(0xFF0D47A1); // Deep Blue
        final accentColor = const Color(0xFF03DAC6); // Teal/Aqua

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeIn(
                  duration: const Duration(milliseconds: 1200),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.currency_bitcoin,
                        color: accentColor,
                        size: 60,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeIn(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 1500),
                  child: Text(
                    "CryptoNavigator",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeIn(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 1500),
                  child: Text(
                    "Track. Analyze. Navigate.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeIn(
                  delay: const Duration(milliseconds: 900),
                  duration: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor:
                          const Color(0xFF1F1F1F), // Card background
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<Widget> _screens = [
    CryptoListScreen(),
    SearchScreen(),
    FavoritesScreen(),
    ProfileScreen(),
    NewsScreen(),
  ];

  final List<String> _titles = [
    'Market',
    'Search',
    'Favorites',
    'Profile',
    'News',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to change tabs
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Market',
              tooltip: 'Market Overview',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
              tooltip: 'Search Cryptocurrencies',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
              tooltip: 'Your Favorite Cryptocurrencies',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'Your Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'News',
              tooltip: 'Crypto News',
            ),
          ],
        ),
      ),
    );
  }
}

// Define these color constants to use throughout your app for price changes
class AppColors {
  static const Color priceUp = Color(0xFF00E676); // Bright Green
  static const Color priceDown = Color(0xFFFF5252); // Bright Red
  static const Color primaryDeepBlue = Color(0xFF0D47A1); // Deep Blue
  static const Color accentTeal = Color(0xFF03DAC6); // Teal/Aqua
  static const Color backgroundDark = Color(0xFF121212); // Almost Black
  static const Color cardBackground = Color(0xFF1F1F1F); // Card Background
  static const Color textColor = Colors.white; // Text Color
}
