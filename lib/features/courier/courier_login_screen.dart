import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../widgets/widgets.dart';
import '../auth/auth_provider.dart';

/// Kuryelere özel giriş ekranı.
/// Normal müşteri login'inden bağımsız; motor FAB'a basınca açılır.
class CourierLoginScreen extends ConsumerStatefulWidget {
  const CourierLoginScreen({super.key});

  @override
  ConsumerState<CourierLoginScreen> createState() => _CourierLoginScreenState();
}

class _CourierLoginScreenState extends ConsumerState<CourierLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      final user = ref.read(authProvider).user;
      AppToast.show(context, 'role: ${user?.role}');
      if (user?.isCourier == true) {
        context.go(AppRoutes.courierOrders);
      } else {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          AppToast.show(context, 'Bu hesap kurye yetkisine sahip değil.');
        }
      }
    } else {
      final error = ref.read(authProvider).error;
      AppToast.show(context, error ?? 'Giriş başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık ────────────────────────────────────────
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.secondaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded,
                        size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text('Kurye Girişi',
                      style: AppTypography.headlineMedium),
                ),
                Center(
                  child: Text(
                    'Kurye hesabınla giriş yap',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── E-posta ────────────────────────────────────────
                Text('E-posta', style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'kurye@ornek.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.secondary, size: 22),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Geçerli bir e-posta gir'
                          : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Şifre ──────────────────────────────────────────
                Text('Şifre', style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.softGray,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Giriş Butonu ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.secondary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdAll),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + 4),
                      elevation: 0,
                    ),
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      loading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
