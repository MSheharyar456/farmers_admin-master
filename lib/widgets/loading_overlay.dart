import 'package:flutter/material.dart';

import '../constants/constants.dart';

class LoadingOverlay extends StatelessWidget {
  final String text;
  final double barrierOpacity;
  final bool showBackdrop;

  const LoadingOverlay({
    super.key,
    this.text = 'Loading...',
    this.barrierOpacity = 0.3,
    this.showBackdrop = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 22,
          right: 22,
          top: 16,
          bottom: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: buttonBackground),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );

    if (!showBackdrop) {
      return Center(child: card);
    }

    return PopScope(
      canPop: false,
      child: Container(
        color: Colors.black.withOpacity(barrierOpacity),
        child: Center(child: card),
      ),
    );
  }
}
