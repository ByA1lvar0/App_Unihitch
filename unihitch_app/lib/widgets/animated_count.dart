import 'package:flutter/material.dart';

class AnimatedCount extends StatefulWidget {
  final num end;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final bool isCurrency;

  const AnimatedCount({
    super.key,
    required this.end,
    this.duration = const Duration(seconds: 2),
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.isCurrency = false,
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.end.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = Tween<double>(begin: 0, end: widget.end.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String text;
        if (widget.isCurrency) {
          text = 'S/. ${_animation.value.toStringAsFixed(2)}';
        } else if (widget.end is int) {
          text = _animation.value.toInt().toString();
        } else {
          text = _animation.value.toStringAsFixed(1);
        }
        return Text(
          '${widget.prefix}$text${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
