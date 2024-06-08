import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inzultz/components/loading_indicator.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/auth.dart';
import 'package:inzultz/screens/manage_settings.dart';
import 'package:inzultz/screens/send.dart';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, GoRouterState state) => AuthScreen(
        mode: (state.extra as Map?)?["mode"] as AuthMode?,
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SendScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const ManageSettings(),
    )
  ],
  redirect: (context, state) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return '/auth';
    }
  },
);

class RouterScreen extends ConsumerWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for Auth changes and .refresh the GoRouter [router]
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _router.refresh();
    });

    var isLoading = ref.watch(appProvider).isLoading;
    return Stack(children: [
      MaterialApp.router(
        routerConfig: _router,
      ),
      if (isLoading) const LoadingScreen()
    ]);
  }
}
