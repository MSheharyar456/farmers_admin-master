import 'dart:async';
import 'package:flutter/material.dart';

class ExpiryCountdownTimer extends StatefulWidget {
  final int expiryMillis;
  final VoidCallback? onDone;

  const ExpiryCountdownTimer({
    super.key,
    required this.expiryMillis,
    this.onDone,
  });

  @override
  State<ExpiryCountdownTimer> createState() => _ExpiryCountdownTimerState();
}

class _ExpiryCountdownTimerState extends State<ExpiryCountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ExpiryCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiryMillis != widget.expiryMillis) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final isStillValuable = _calculateRemainingTime();

    if (isStillValuable) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _calculateRemainingTime(),
      );
    }
  }

  /// Returns true if there is still remaining time
  bool _calculateRemainingTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = widget.expiryMillis - now;

    if (diff <= 0) {
      _timer?.cancel();
      _timer = null;
      if (mounted) {
        setState(() => _remaining = Duration.zero);
        // Schedule the callback to avoid build-phase errors
        if (widget.onDone != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onDone!();
          });
        }
      }
      return false;
    } else {
      if (mounted) {
        setState(() => _remaining = Duration(milliseconds: diff));
      }
      return true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final milliseconds = _remaining.inMilliseconds.remainder(1000);

    return Text(
      '${days}d ${hours}h ${minutes}m ${seconds}s',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }
}
