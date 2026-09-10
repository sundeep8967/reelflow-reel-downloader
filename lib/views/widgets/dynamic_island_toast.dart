import 'dart:ui';
import 'package:flutter/cupertino.dart';

class DynamicIslandToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final bool isVisible;

  const DynamicIslandToast({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.checkmark_alt_circle_fill,
    this.iconColor = CupertinoColors.activeGreen,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      top: isVisible ? 12 : -80,
      left: 20,
      right: 20,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isVisible ? 1.0 : 0.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.none,
                        ),
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
