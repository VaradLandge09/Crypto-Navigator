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
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: CryptoApp(),
    ),
  );
}

// Theme provider to handle theme switching
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  // Dark theme
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6200EE),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6200EE),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Color(0xFFCF6679),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: const Color(0xFF6200EE),
      unselectedItemColor: Colors.grey[500],
      backgroundColor: const Color(0xFF1E1E1E),
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
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
      ),
    ),
  );

  // Light theme
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6200EE),
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6200EE),
      secondary: Color(0xFF03DAC6),
      surface: Colors.white,
      background: Color(0xFFF8F8F8),
      error: Color(0xFFB00020),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: const Color(0xFF6200EE),
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
      ),
    ),
  );
}

// In your main.dart file, update the CryptoApp class:

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Tracker',
      theme: themeProvider.currentTheme,
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

        // Use our enhanced loading screen for the initial loading state
        // while maintaining the same structure
        final primaryColor = Theme.of(context).primaryColor;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final textColor = Theme.of(context).textTheme.titleLarge?.color;

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Check if logo asset exists, otherwise use animated icon
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
                        color: isDarkMode
                            ? const Color(0xFF03DAC6)
                            : primaryColor.withOpacity(0.8),
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
                      color: textColor,
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
                      color: textColor?.withOpacity(0.7),
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
                      backgroundColor: isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
    'CryptoNavigator',
    'CryptoNavigator',
    'CryptoNavigator',
    'CryptoNavigator',
    'CryptoNavigator',
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
          ),

          // Notification bell (can be implemented later)
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
              color: Colors.black.withOpacity(0.1),
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
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                // Add portfolio or refresh function depending on the screen
                if (_selectedIndex == 0) {
                  // Refresh market data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing market data...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (_selectedIndex == 2) {
                  // Add to favorites - navigate to search
                  setState(() {
                    _selectedIndex = 1;
                    _tabController.animateTo(1);
                  });
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                _selectedIndex == 0 ? Icons.refresh : Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
