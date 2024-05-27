import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inzultz/components/loading_indicator.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/send.dart';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SendScreen(),
    ),
  ],
);

class RouterScreen extends ConsumerWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isLoading = ref.watch(appProvider).isLoading;
    return Stack(children: [
      MaterialApp.router(
        routerConfig: _router,
      ),
      if (isLoading) const LoadingScreen()
    ]);
  }
}
