import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../widgets/widgets.dart';

/// OTP (SMS kodu) doğrulama ekranı.
///
/// 6 haneli kod girişi, otomatik odak geçişi ve yeniden gönder geri sayımı.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone});

  final String? phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  bool _loading = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == _length) _verify();
  }

  Future<void> _verify() async {
    if (_code.length < _length) {
      AppToast.show(context, 'Lütfen $_length haneli kodu gir');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _loading = false);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doğrulama kodu', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.phone != null
                    ? '${widget.phone} numarasına gönderdiğimiz $_length haneli kodu gir'
                    : 'Telefonuna gönderdiğimiz $_length haneli kodu gir',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),

              Row(
                children: List.generate(
                  _length,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == _length - 1 ? 0 : AppSpacing.xs,
                      ),
                      child: _otpBox(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Doğrula',
                variant: AppButtonVariant.gradient,
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: _secondsLeft > 0
                    ? Text('Kodu tekrar gönder: 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: AppTypography.bodyMedium)
                    : TextButton(
                        onPressed: () {
                          _startTimer();
                          AppToast.show(context, 'Yeni kod gönderildi');
                        },
                        child: Text('Kodu tekrar gönder',
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.primary)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      height: 64,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.headlineLarge,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(counterText: ''),
        onChanged: (v) => _onChanged(index, v),
      ),
    );
  }
}
