import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _colorTween = _animationController.drive(ColorTween(
      begin: Colors.tealAccent,
      end: Colors.blue,
    ));

    _animationController.repeat(reverse: true);

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeCap: StrokeCap.round,
        valueColor: _colorTween,
        strokeWidth: 8,
      ),
    );
  }
}
