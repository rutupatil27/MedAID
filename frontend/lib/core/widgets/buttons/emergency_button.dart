import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// The SOS control: a large emergency-coloured circle the user presses and
/// holds for [AppDurations.sosHold]. A progress ring shows how long is left.
/// Holding prevents accidental alerts without slowing a real one (OQ-14).
///
/// Screen-reader users activate it with a normal double-tap (semantic tap).
class EmergencyButton extends StatefulWidget {
  const EmergencyButton({
    super.key,
    required this.label,
    required this.hint,
    required this.semanticLabel,
    required this.onActivated,
    this.enabled = true,
    this.size = AppSizes.sosButton,
  });

  /// Large text inside the button, e.g. "SOS".
  final String label;

  /// Instruction below the label, e.g. "Hold for help".
  final String hint;
  final String semanticLabel;
  final VoidCallback onActivated;
  final bool enabled;
  final double size;

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: AppDurations.sosHold,
  )..addStatusListener(_onHoldStatus);

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.heavyImpact();
      widget.onActivated();
      _hold.reset();
    }
  }

  void _start() {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _cancel() {
    if (_hold.isAnimating) _hold.reverse();
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = widget.enabled ? palette.emergency : context.palette.textMuted;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onActivated : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final progress = _hold.value;
            return SizedBox.square(
              dimension: widget.size + AppSpacing.xxxl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft halo that grows while holding.
                  Container(
                    width: widget.size + AppSpacing.xxxl * progress,
                    height: widget.size + AppSpacing.xxxl * progress,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.emergencyContainer,
                    ),
                  ),
                  SizedBox.square(
                    dimension: widget.size + AppSpacing.sm,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: AppSpacing.xs + AppSpacing.xxs,
                      color: palette.emergencyDark,
                      backgroundColor: AppColors.transparent,
                    ),
                  ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: background,
                      boxShadow: widget.enabled ? AppShadows.emergencyGlow : null,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.label,
                          style: context.textStyles.displaySmall?.copyWith(
                            color: palette.onEmergency,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.hint,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: context.textStyles.labelMedium?.copyWith(
                            color: palette.onEmergency,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
