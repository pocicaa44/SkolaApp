import 'dart:async';
import 'package:flutter/material.dart';

/// Widget khusus yang mengisolasi rebuild timer per detik.
/// Hanya subtree di dalam [builder] yang akan di-rebuild setiap detik,
/// menjaga performa halaman utama (Dashboard/Attendance) tetap mulus tanpa re-render pohon widget besar.
class RealtimeTickerBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;

  const RealtimeTickerBuilder({super.key, required this.builder});

  @override
  State<RealtimeTickerBuilder> createState() => _RealtimeTickerBuilderState();
}

class _RealtimeTickerBuilderState extends State<RealtimeTickerBuilder> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _now);
  }
}
