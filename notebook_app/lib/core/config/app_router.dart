/// Uygulama yönlendirme yapılandırması (GoRouter)
/// Auth durumuna göre otomatik yönlendirme
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/editor/note_editor_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/share/share_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isAuth && !isAuthRoute) return '/auth';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/editor/:noteId',
        builder: (context, state) => NoteEditorScreen(
          noteId: state.pathParameters['noteId']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/share/:noteId',
        builder: (context, state) => ShareNoteScreen(
          noteId: state.pathParameters['noteId']!,
        ),
      ),
    ],
  );
});

/// GoRouter refresh stream yardımcısı
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
