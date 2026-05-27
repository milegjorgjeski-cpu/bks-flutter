import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BksProgressCard extends StatelessWidget {
  final int progress;
  final String message;
  final bool isComplete;

  const BksProgressCard({super.key, required this.progress,
      required this.message, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFF0A1A0A) : BksColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isComplete ? BksColors.success : BksColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isComplete ? '✅ ЗАВРШЕНО' : 'ОБРАБОТУВА',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 2, color: isComplete ? BksColors.success : BksColors.textMuted)),
          const Spacer(),
          Text('$progress%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: isComplete ? BksColors.success : BksColors.gold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress / 100, minHeight: 5,
            backgroundColor: BksColors.bg3,
            valueColor: AlwaysStoppedAnimation(isComplete ? BksColors.success : BksColors.gold),
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(fontSize: 12, color: BksColors.textSecondary)),
      ]),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 2.5, color: BksColors.textMuted)),
  );
}

class BksCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final EdgeInsets? padding;

  const BksCard({super.key, required this.child, this.glowColor, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: BksColors.bg1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: glowColor != null
          ? glowColor!.withOpacity(0.4) : BksColors.border),
      boxShadow: glowColor != null
          ? [BoxShadow(color: glowColor!.withOpacity(0.15), blurRadius: 16)]
          : null,
    ),
    child: child,
  );
}

class SmallBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const SmallBtn({super.key, required this.label, required this.active,
      required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: active ? activeColor : BksColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: active ? activeColor : BksColors.textMuted, letterSpacing: 1)),
    ),
  );
}
