import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

/// A 3-step bottom-sheet PIN change flow:
///   Step 1 — verify current PIN
///   Step 2 — enter new PIN
///   Step 3 — confirm new PIN → save
class ChangePinSheet extends StatefulWidget {
  const ChangePinSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePinSheet(),
    );
  }

  @override
  State<ChangePinSheet> createState() => _ChangePinSheetState();
}

enum _Step { current, newPin, confirm }

class _ChangePinSheetState extends State<ChangePinSheet> {
  final SecurityService _security = SecurityService();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  _Step _step = _Step.current;
  bool _loading = false;
  String? _error;

  // Cache the new PIN between step 2 → 3
  String _pendingNewPin = '';

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Step configs ──────────────────────────────────────────────────────────

  String get _title => switch (_step) {
    _Step.current => 'Verify Current PIN',
    _Step.newPin  => 'Enter New PIN',
    _Step.confirm => 'Confirm New PIN',
  };

  String get _subtitle => switch (_step) {
    _Step.current => 'Enter your existing PIN to continue',
    _Step.newPin  => 'Choose a new 4-digit PIN',
    _Step.confirm => 'Re-enter your new PIN to confirm',
  };

  String get _buttonLabel => switch (_step) {
    _Step.current => 'Verify',
    _Step.newPin  => 'Next',
    _Step.confirm => 'Change PIN',
  };

  TextEditingController get _activeCtrl => switch (_step) {
    _Step.current => _currentCtrl,
    _Step.newPin  => _newCtrl,
    _Step.confirm => _confirmCtrl,
  };

  FocusNode get _activeFocus => switch (_step) {
    _Step.current => _currentFocus,
    _Step.newPin  => _newFocus,
    _Step.confirm => _confirmFocus,
  };

  IconData get _stepIcon => switch (_step) {
    _Step.current => Icons.lock_outline,
    _Step.newPin  => Icons.lock_open_outlined,
    _Step.confirm => Icons.check_circle_outline,
  };

  Color get _stepColor => switch (_step) {
    _Step.current => AppTheme.isDarkMode ? AppTheme.onSurface : AppTheme.primary,
    _Step.newPin  => AppTheme.accent,
    _Step.confirm => AppTheme.success,
  };

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onPrimary() async {
    setState(() { _error = null; _loading = true; });

    final pin = _activeCtrl.text.trim();

    switch (_step) {
      case _Step.current:
        final valid = await _security.verifyPin(pin);
        if (!mounted) return;
        if (valid) {
          setState(() { _step = _Step.newPin; _loading = false; });
          await Future.delayed(const Duration(milliseconds: 80));
          _newFocus.requestFocus();
        } else {
          setState(() { _error = 'Incorrect PIN. Please try again.'; _loading = false; });
          _currentCtrl.clear();
        }

      case _Step.newPin:
        if (pin.length != 4) {
          setState(() { _error = 'PIN must be exactly 4 digits.'; _loading = false; });
          return;
        }
        _pendingNewPin = pin;
        setState(() { _step = _Step.confirm; _loading = false; });
        await Future.delayed(const Duration(milliseconds: 80));
        _confirmFocus.requestFocus();

      case _Step.confirm:
        if (pin != _pendingNewPin) {
          setState(() { _error = 'PINs do not match. Try again.'; _loading = false; });
          _confirmCtrl.clear();
          return;
        }
        await _security.savePin(_pendingNewPin);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN changed successfully! 🔒',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  // ── Step progress indicator ───────────────────────────────────────────────

  Widget _stepDot(int index) {
    final currentIndex = _step.index;
    final active = index == currentIndex;
    final done = index < currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: done
            ? AppTheme.success
            : active
                ? _stepColor
                : AppTheme.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 24),

          // ── Step progress dots ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepDot(0),
              const SizedBox(width: 6),
              _stepDot(1),
              const SizedBox(width: 6),
              _stepDot(2),
            ],
          ),

          const SizedBox(height: 22),

          // ── Icon ────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: CircleAvatar(
              key: ValueKey(_step),
              radius: 32,
              backgroundColor: _stepColor.withValues(alpha: 0.12),
              child: Icon(_stepIcon, color: _stepColor, size: 30),
            ),
          ),

          const SizedBox(height: 16),

          // ── Title & subtitle ─────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey(_step),
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── PIN input ────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _PinField(
              key: ValueKey(_step),
              controller: _activeCtrl,
              focusNode: _activeFocus,
              stepColor: _stepColor,
              onSubmitted: (_) => _onPrimary(),
              autofocus: _step == _Step.current,
            ),
          ),

          // ── Error ─────────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error != null
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppTheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // ── Primary button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: _stepColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _stepColor.computeLuminance() > 0.5
                              ? AppTheme.primary
                              : Colors.white))
                  : Text(
                      _buttonLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _stepColor.computeLuminance() > 0.5
                              ? AppTheme.primary
                              : Colors.white),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Cancel ───────────────────────────────────────────────────────
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable PIN text field — hidden digits, numeric keyboard, centered
// ─────────────────────────────────────────────────────────────────────────────

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color stepColor;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const _PinField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.stepColor,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      obscureText: true,
      textAlign: TextAlign.center,
      maxLength: 4,
      style: TextStyle(
        fontSize: 20,
        letterSpacing: 10,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: '••••',
        counterText: '',
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stepColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stepColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: stepColor, width: 2),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
