import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();
  final SecurityService _security = SecurityService();

  bool _isLoading = false;
  bool _isAuthenticating = false;
  DateTime? _lastAttemptTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay ensures platform is ready on initial mount
      Future.delayed(const Duration(milliseconds: 1000), _tryBiometric);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Debounce: prevent back-to-back prompts after cancelling
      final now = DateTime.now();
      if (_lastAttemptTime != null &&
          now.difference(_lastAttemptTime!).inSeconds < 10) {
        return;
      }

      // Re-trigger biometric whenever the app is resumed while locked
      Future.delayed(const Duration(milliseconds: 1000), _tryBiometric);
    }
  }

  /// ================= BIOMETRIC =================
  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    _lastAttemptTime = DateTime.now();

    final success = await _security.authenticateBiometric();

    if (!mounted) {
      _isAuthenticating = false;
      return;
    }

    if (success) {
      context.read<AppStateProvider>().unlockApp();
    }

    _isAuthenticating = false;
  }

  /// ================= VERIFY PIN =================
  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final valid = await _security.verifyPin(_pinController.text.trim());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (valid) {
      context.read<AppStateProvider>().unlockApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Invalid PIN",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: "••••",
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: .4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// ================= LOGO =================
                  Text(
                    "I-W-¡-³-",
                    style: TextStyle(
                      fontFamily: 'Ravivarma',
                      fontSize: 64,
                      color: AppTheme.accent,
                    ),
                  ),

                  Text(
                    "Unlock your finances",
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ================= CARD =================
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.divider,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// PIN INPUT
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          maxLength: 4,
                          style: const TextStyle(
                            fontSize: 26,
                            letterSpacing: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: _inputDecoration(),
                          onSubmitted: (_) => _verifyPin(),
                        ),

                        const SizedBox(height: 12),

                        /// UNLOCK BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "Unlock",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// BIOMETRIC BUTTON
                        TextButton.icon(
                          onPressed: _tryBiometric,
                          icon: Icon(
                            Icons.fingerprint,
                            size: 26,
                            color: AppTheme.accent,
                          ),
                          label: Text(
                            "Unlock with biometric",
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Authentication keeps your financial data secure",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
