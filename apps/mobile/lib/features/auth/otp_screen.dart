import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';

class OtpArgs {
  const OtpArgs({required this.target, required this.purpose});

  final String target;
  final String purpose;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _seconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 4) {
      _show('أدخل رمز التحقق');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            target: widget.args.target,
            code: _code.text.trim(),
            purpose: widget.args.purpose,
          );
      await ref.read(authControllerProvider.notifier).completeWithTokens(result);
      // Router redirects to /home.
    } on ApiException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('رمز غير صحيح.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref
          .read(authRepositoryProvider)
          .resendOtp(target: widget.args.target, purpose: widget.args.purpose);
      _startCountdown();
      _show('تم إرسال رمز جديد', error: false);
    } on ApiException catch (e) {
      _show(e.message);
    }
  }

  void _show(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رمز التحقق')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.mark_email_read_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text(
                'أدخل رمز التحقق',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'أرسلنا رمزاً إلى ${widget.args.target}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تأكيد'),
              ),
              const SizedBox(height: 16),
              Center(
                child: _seconds > 0
                    ? Text('إعادة الإرسال خلال $_seconds ثانية',
                        style: const TextStyle(color: AppColors.muted))
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('إعادة إرسال الرمز'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
