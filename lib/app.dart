import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'core/localization/app_localizations.dart';
import 'features/products/presentation/screens/home_screen.dart';
import 'features/products/presentation/screens/price_drops_screen.dart';
import 'features/products/presentation/screens/add_product_screen.dart';
import 'features/products/presentation/screens/product_detail_screen.dart';
import 'features/groups/presentation/screens/group_comparison_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'shared/widgets/app_bars/bottom_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const MaterialPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/price-drops',
            pageBuilder: (context, state) => const MaterialPage(
              child: PriceDropsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const MaterialPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add-product',
        pageBuilder: (context, state) {
          final initialUrl = state.uri.queryParameters['url'];
          return MaterialPage(
            child: AddProductScreen(initialUrl: initialUrl),
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id']!;
          return MaterialPage(
            child: ProductDetailScreen(productId: productId),
          );
        },
      ),
      GoRoute(
        path: '/group/:id',
        pageBuilder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return MaterialPage(
            child: GroupComparisonScreen(groupId: groupId),
          );
        },
      ),
    ],
  );
});

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final location = router.routeInformationProvider.value.uri.toString();

    // Update current index based on location
    if (location.startsWith('/home')) {
      _currentIndex = 0;
    } else if (location.startsWith('/price-drops')) {
      _currentIndex = 1;
    } else if (location.startsWith('/settings')) {
      _currentIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/price-drops');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}

class App extends ConsumerStatefulWidget {
  final String? sharedUrl;

  const App({super.key, this.sharedUrl});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Handle shared URL after the app is initialized
    if (widget.sharedUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to add product screen with the shared URL
        context.go('/add-product?url=${Uri.encodeComponent(widget.sharedUrl!)}');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes to foreground, refresh products that haven't been checked recently
    if (state == AppLifecycleState.resumed) {
      _refreshStaleProducts();
    }
  }

  Future<void> _refreshStaleProducts() async {
    try {
      // Get products that haven't been checked in the last 6 hours
      final repository = ref.read(productRepositoryProvider);
      final staleProducts = await repository.getStaleProducts(const Duration(hours: 6));

      // Refresh stale products (limit to 3 at a time to avoid overwhelming the system)
      for (var i = 0; i < staleProducts.length && i < 3; i++) {
        try {
          await repository.refreshProductPrice(staleProducts[i].id);
        } catch (e) {
          // Continue with other products even if one fails
          // ignore: avoid_print
          print('Error refreshing product ${staleProducts[i].id}: $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in foreground refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize notifications and background services
    ref.watch(appInitializationProvider);

    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PriceWatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
