import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/widgets.dart';

/// Şifremi unuttum ekranı.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _formView() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Endişelenme', style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('E-posta adresini gir, sana şifre sıfırlama bağlantısı gönderelim',
                style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              label: 'E-posta',
              hint: 'ornek@email.com',
              controller: _email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Geçerli bir e-posta gir' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Bağlantı Gönder',
              variant: AppButtonVariant.gradient,
              loading: _loading,
              onPressed: _send,
            ),
          ],
        ),
      );

  Widget _successView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  size: 56, color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('E-posta gönderildi', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('${_email.text} adresine bağlantı gönderdik. Gelen kutunu kontrol et.',
                textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Girişe Dön',
              variant: AppButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      );
}
