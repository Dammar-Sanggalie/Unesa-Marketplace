import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/breakpoints.dart';
import 'core/constants/colors.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/listing/add_listing_screen.dart';
import 'screens/listing/my_listings_screen.dart';
import 'screens/listing/saved_items_screen.dart';
import 'screens/web/web_header.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const ProviderScope(child: UnesaMarketplaceApp()));
}

class UnesaMarketplaceApp extends StatelessWidget {
  const UnesaMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNESA Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AnimatedSplashScreen(),
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();

    // Tunggu sebentar lalu ke halaman utama
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Image.asset(
                  'assets/image/Logo_apliaksi_marketplace-removebg-preview.png',
                  width: 200,
                  height: 200,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const MainNavigator();
        }
        return const AuthScreen();
      },
    );
  }
}

final GlobalKey<ExploreScreenState> _exploreKey = GlobalKey<ExploreScreenState>();

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  // Mobile tab index (0: Explore, 1: Pesan, 2: Profil)
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  // Desktop active tab (0: Explore, 1: Sell, 2: My Listings, 3: Saved, 4: Chat, 5: Profile)
  int _desktopIndex = 0;

  final List<Widget> _mobileScreens = [
    ExploreScreen(key: _exploreKey),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void switchMobileTab(int index) {
    setState(() {
      _currentIndex = index;
      _mobileScreens[1] = ChatListScreen(key: UniqueKey());
    });
  }

  void switchDesktopTab(int index) {
    setState(() {
      _desktopIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktopOrTablet(context);

    if (isDesktop) {
      return _buildDesktopShell(context);
    }
    return _buildMobileShell(context);
  }

  // DESKTOP FULL-WIDTH WEB SHELL
  Widget _buildDesktopShell(BuildContext context) {
    Widget currentContent;
    switch (_desktopIndex) {
      case 0:
        currentContent = ExploreScreen(
          key: _exploreKey,
          onNavigateToSell: () => switchDesktopTab(1),
        );
        break;
      case 1:
        currentContent = const AddListingScreen();
        break;
      case 2:
        currentContent = const MyListingsScreen();
        break;
      case 3:
        currentContent = SavedItemsScreen(
          onExploreTap: () => switchDesktopTab(0),
        );
        break;
      case 4:
        currentContent = ChatListScreen(key: UniqueKey());
        break;
      case 5:
        currentContent = ProfileScreen(
          onNavigateToListings: () => switchDesktopTab(2),
          onNavigateToSaved: () => switchDesktopTab(3),
        );
        break;
      default:
        currentContent = ExploreScreen(key: _exploreKey);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          WebHeader(
            activeIndex: _desktopIndex,
            onSelectTab: switchDesktopTab,
          ),
          Expanded(
            child: currentContent,
          ),
        ],
      ),
    );
  }

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileShell(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          switchMobileTab(0);
          return;
        }

        final cleared = _exploreKey.currentState?.clearSearch() ?? false;
        if (cleared) return;

        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), duration: Duration(seconds: 2)),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _mobileScreens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: switchMobileTab,
          backgroundColor: AppColors.surface,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Pesan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
