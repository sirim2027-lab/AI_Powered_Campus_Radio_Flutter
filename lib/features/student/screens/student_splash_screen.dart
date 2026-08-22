import 'dart:async';

import 'package:flutter/material.dart';

class StudentSplashScreen extends StatefulWidget {
  const StudentSplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<StudentSplashScreen> createState() => _StudentSplashScreenState();
}

class _StudentSplashScreenState extends State<StudentSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 2500), widget.onComplete);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(top: -80, right: -80, child: _Glow(size: 280)),
              const Positioned(bottom: -60, left: -60, child: _Glow(size: 220)),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: .3)),
                        ),
                        child: const Icon(Icons.hub_outlined, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 28),
                      const Text('VEMANA INSTITUTE OF TECHNOLOGY', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      const Text.rich(TextSpan(children: [TextSpan(text: 'Campus', style: TextStyle(color: Colors.white)), TextSpan(text: 'Connect', style: TextStyle(color: Color(0xFFA5B4FC)))]), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w400)),
                      const SizedBox(height: 6),
                      const Text('AI-Powered Smart Campus Platform', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 48,
                right: 48,
                bottom: 56,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Loading resources…', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)), Text('${(_controller.value * 100).round()}%', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11))]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _controller.value, minHeight: 3, color: const Color(0xFFA5B4FC), backgroundColor: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: const BoxDecoration(color: Color(0x0DFFFFFF), shape: BoxShape.circle));
}
