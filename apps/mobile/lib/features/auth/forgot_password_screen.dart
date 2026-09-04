import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snack.dart';
import '../../providers/core_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _target = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _target.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Normalizes any accepted Saudi format to E.164 (+9665XXXXXXXX).
  static String _normalizeSaudi(String v) {
    var d = v.replaceAll(RegExp(r'[\s-]'), '');
    d = d.replaceFirst(RegExp(r'^(\+966|00966|966|0)'), '');
    return '+966$d';
  }

  String get _phone => _normalizeSaudi(_target.text.trim());

  Future<void> _request() async {
    if (!RegExp(
      r'^(\+966|00966|966|0)?5\d{8}$',
    ).hasMatch(_target.text.replaceAll(RegExp(r'[\s-]'), ''))) {
      _show('أدخل رقم جوال سعودي صحيح (05XXXXXXXX)');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_phone);
      setState(() => _sent = true);
      _show('تم إرسال رمز الاستعادة', error: false);
    } on ApiException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length < 4 || _password.text.length < 8) {
      _show('تحقّق من الرمز وكلمة المرور');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            target: _phone,
            code: _code.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      _show('تم تغيير كلمة المرور بنجاح', error: false);
      context.pop();
    } on ApiException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String msg, {bool error = true}) {
    if (error) {
      showErrorSnack(context, msg);
    } else {
      showSuccessSnack(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.lock_reset, size: 60, color: AppColors.primary),
              const SizedBox(height: 20),
              TextField(
                controller: _target,
                enabled: !_sent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال',
                  hintText: '05XXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              if (_sent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'رمز التحقق',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : (_sent ? _reset : _request),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(_sent ? 'تغيير كلمة المرور' : 'إرسال الرمز'),
              ),
              if (_sent)
                TextButton(
                  onPressed: _busy ? null : _request,
                  child: const Text('إعادة إرسال الرمز'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
