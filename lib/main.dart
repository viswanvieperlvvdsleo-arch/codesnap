import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout_screen.dart';
import 'widgets/elastic_scroll_view.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const CodeSnapApp(),
    ),
  );
}

class CodeSnapApp extends StatelessWidget {
  const CodeSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Bug',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      // ── Global bouncing scroll + predictive back transitions ──
      scrollBehavior: const BouncingScrollBehavior(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: ScrollConfiguration(
            behavior: const BouncingScrollBehavior(),
            child: child!,
          ),
        );
      },
      home: authProvider.isLoading
          ? const LoadingGate()
          : authProvider.isAuthenticated
              ? const MainLayoutScreen()
              : const LoginScreen(),
    );
  }
}

class LoadingGate extends StatefulWidget {
  const LoadingGate({super.key});

  @override
  State<LoadingGate> createState() => _LoadingGateState();
}

class _LoadingGateState extends State<LoadingGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider.backgroundWarmWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing gold ring
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeProvider.primaryGold
                        .withOpacity(_pulse.value),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeProvider.primaryGold
                          .withOpacity(_pulse.value * 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeProvider.primaryGold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Bug',
              style: TextStyle(
                color: ThemeProvider.primaryGold,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Loading your workspace...',
              style: TextStyle(
                color: ThemeProvider.textMutedGray,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
