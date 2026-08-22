import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message = 'Loading your campus workspace…'});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 14), Text(message)])),
      );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Try again',
  });
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 52), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: onRetry, child: Text(actionLabel))]))),
      );
}
