import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds every second with the time left until [until] (mm:ss).
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.until, required this.builder, this.style});

  final DateTime until;

  /// Receives the formatted remaining time, e.g. "01:42" ("00:00" when over).
  final String Function(String remaining) builder;
  final TextStyle? style;

  static String format(Duration remaining) {
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final minutes = safe.inMinutes.toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (DateTime.now().isAfter(widget.until)) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = CountdownText.format(widget.until.difference(DateTime.now()));
    return Text(widget.builder(remaining), style: widget.style);
  }
}
