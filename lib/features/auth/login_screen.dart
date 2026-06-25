import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../widgets/widgets.dart';
import 'auth_provider.dart';

const _kDomains = ['gmail.com', 'outlook.com', 'hotmail.com', 'yahoo.com', 'icloud.com', 'hopp.com', 'hopp.com.tr'];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _selectedDomain = _kDomains[0];
  bool _obscurePassword = true;

  late final AnimationController _bannerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<Offset> _bannerSlide = Tween<Offset>(
    begin: const Offset(0, -1.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _bannerController,
    curve: Curves.easeOutCubic,
  ));
  late final Animation<double> _bannerFade = CurvedAnimation(
    parent: _bannerController,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _bannerController.forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _fullEmail => '${_username.text.trim()}@$_selectedDomain';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(_fullEmail, _password.text);
    if (!mounted) return;
    if (ok) {
      final user = ref.read(authProvider).user;
      if (user?.isCourier == true) {
        context.go(AppRoutes.courierOrders);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      final error = ref.read(authProvider).error;
      AppToast.show(context, error ?? 'Giriş başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── Logo ───────────────────────────────────────
                FadeTransition(
                  opacity: _bannerFade,
                  child: SlideTransition(
                    position: _bannerSlide,
                    child: SizedBox(
                      height: 150,
                      child: Image.asset(
                        'assets/images/logo_hopp.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.delivery_dining_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Beyaz kart ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxs,
                      AppSpacing.xxs,
                      AppSpacing.xxs,
                      AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgAll,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FadeTransition(
                            opacity: _bannerFade,
                            child: SlideTransition(
                              position: _bannerSlide,
                              child: Text(
                                'Hoşgeldin!',
                                textAlign: TextAlign.center,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Hopp Kapında ile hızlı ve kolay giriş yap.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.softGray),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // ── E-posta: kullanıcı adı + domain dropdown ───
                        Text('E-posta', style: AppTypography.labelMedium),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _username,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.bodyLarge,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Kullanıcı adını gir'
                              : null,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            hintText: 'kullanıcı adı',
                            prefixIcon: const Icon(Icons.mail_outline_rounded,
                                color: AppColors.secondary, size: 18),
                            suffixIcon: _DomainDropdown(
                              value: _selectedDomain,
                              domains: _kDomains,
                              onChanged: (d) =>
                                  setState(() => _selectedDomain = d),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── Şifre ──────────────────────────────────────
                        _ColoredTextField(
                          label: 'Şifre',
                          hint: '••••••',
                          controller: _password,
                          prefixIcon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFF2D7FF9),
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'En az 6 karakter'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            child: Text(
                              'Şifremi unuttum',
                              style: AppTypography.labelMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // ── Giriş Yap ──────────────────────────────────
                        _PrimaryLoginButton(
                          label: 'Giriş Yap',
                          loading: loading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── veya ────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: AppColors.divider, thickness: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Text(
                                'veya',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.softGray),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: AppColors.divider, thickness: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ── Kayıt Ol ───────────────────────────────────
                        AppButton(
                          label: 'HESAP OLUŞTUR',
                          variant: AppButtonVariant.outline,
                          icon: Icons.person_add_outlined,
                          onPressed: () => context.push(AppRoutes.register),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '2026 © HOPP KAPINDA TÜM HAKLARI SAKLIDIR.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Footer (KVKK / Kullanım Şartları) ───────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white.withOpacity(0.85)),
                      children: const [
                        TextSpan(text: 'Devam ederek '),
                        TextSpan(
                          text: 'KVKK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Kullanım Şartları',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: "'nı kabul etmiş olursunuz."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Giriş Yap birincil butonu — sağda ok ikonlu özel tasarım ────────────────
class _PrimaryLoginButton extends StatefulWidget {
  const _PrimaryLoginButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryLoginButton> createState() => _PrimaryLoginButtonState();
}

class _PrimaryLoginButtonState extends State<_PrimaryLoginButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (_enabled) setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.6,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: AppRadius.mdAll,
              boxShadow: AppShadows.brandGlow,
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Domain seçici (suffix widget) — modern pill + bottom sheet ──────────────
class _DomainDropdown extends StatefulWidget {
  const _DomainDropdown({
    required this.value,
    required this.domains,
    required this.onChanged,
  });

  final String value;
  final List<String> domains;
  final ValueChanged<String> onChanged;

  @override
  State<_DomainDropdown> createState() => _DomainDropdownState();
}

class _DomainDropdownState extends State<_DomainDropdown> {
  bool _pressed = false;

  Future<void> _openPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DomainPickerSheet(
        domains: widget.domains,
        selected: widget.value,
      ),
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _openPicker,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.14),
                width: 1,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '@',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.value,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.softGray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Domain seçim sayfası (bottom sheet içeriği) ──────────────────────────────
class _DomainPickerSheet extends StatelessWidget {
  const _DomainPickerSheet({
    required this.domains,
    required this.selected,
  });

  final List<String> domains;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.softGray.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Text(
              'E-posta Sağlayıcısı',
              style: AppTypography.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...domains.map((d) {
            final isSelected = d == selected;
            return InkWell(
              onTap: () => Navigator.pop(context, d),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.softGray,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '@$d',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Renkli ikonlu text field ─────────────────────────────────────────────────
class _ColoredTextField extends StatelessWidget {
  const _ColoredTextField({
    required this.label,
    required this.controller,
    required this.prefixIcon,
    required this.iconColor,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final Color iconColor;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: iconColor, size: 18),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.softGray,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
