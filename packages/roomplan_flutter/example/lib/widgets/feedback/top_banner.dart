import 'dart:async';

import 'package:flutter/material.dart';

/// Banner that slides in from the top, stays visible, then slides out.
class TopBanner extends StatefulWidget {
  const TopBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<TopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          widget.onDismissed();
        }
      })
      ..forward();
    _timer = Timer(const Duration(seconds: 5), _controller.reverse);
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.5),
            end: Offset.zero,
          ).animate(curved),
          child: GestureDetector(
            onTap: _controller.reverse,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < 0) {
                _controller.reverse();
              }
            },
            child: Material(
              color: colors.primaryContainer,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
