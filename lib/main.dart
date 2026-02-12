import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/browse_page.dart';
import 'presentation/pages/search_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/pages/favorites_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/stats_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PoseReferenceApp());
}

class PoseReferenceApp extends StatelessWidget {
  const PoseReferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: RouteConstants.splash,
  routes: [
    GoRoute(
      path: RouteConstants.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: RouteConstants.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: RouteConstants.browse,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        // 支持12位编码筛选参数
        final filters = extra.map((key, value) => MapEntry(key, value.toString()));
        return BrowsePage(
          filters: filters.isNotEmpty ? filters : null,
        );
      },
    ),
    GoRoute(
      path: RouteConstants.search,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '${RouteConstants.detail}/path/:encodedPath',
      builder: (context, state) {
        final encodedPath = state.pathParameters['encodedPath']!;
        final imageList = state.uri.queryParameters['list'];
        return DetailPage(
          poseId: 'path/$encodedPath',
          imageList: imageList,
        );
      },
    ),
    GoRoute(
      path: '${RouteConstants.detail}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DetailPage(poseId: id);
      },
    ),
    GoRoute(
      path: RouteConstants.favorites,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: RouteConstants.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: RouteConstants.stats,
      builder: (context, state) => const StatsPage(),
    ),
  ],
);
