import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/capture/capture_screen.dart';
import '../features/capture/region_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/splash_screen.dart';
import '../features/save/save_screen.dart';
import '../features/select/select_screen.dart';
import '../features/settings/settings_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const home = '/';
  static const capture = '/capture';
  static const region = '/capture/region';
  static const select = '/capture/select';
  static const save = '/capture/select/save';
  static const settings = '/settings';
  static String detail(String id) => '/quote/$id';
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

GoRouter buildRouter({String initialLocation = Routes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'capture',
            builder: (context, state) => const CaptureScreen(),
            routes: [
              GoRoute(
                path: 'region',
                builder: (context, state) => const RegionScreen(),
              ),
              GoRoute(
                path: 'select',
                builder: (context, state) => const SelectScreen(),
                routes: [
                  GoRoute(
                    path: 'save',
                    builder: (context, state) => const SaveScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'quote/:id',
            builder: (context, state) =>
                DetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
