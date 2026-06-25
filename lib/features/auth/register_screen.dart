import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../widgets/widgets.dart';
import '../address/location_picker_screen.dart';
import '../address/address_provider.dart';
import 'auth_provider.dart';

/// Kayıt ekranı.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _emailUsername = TextEditingController();
  String _emailDomain = 'gmail.com';
  final _password = TextEditingController();
  final _address = TextEditingController();
  bool _acceptTerms = false;
  LocationResult? _pickedLocation;
  String? _addressError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _emailUsername.dispose();
    _password.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    setState(() {
      _pickedLocation = result;
      // Adres alanını tam adresle doldur
      _address.text = [
        result.address,
        if (result.district.isNotEmpty) result.district,
        if (result.city.isNotEmpty) result.city,
      ].join(', ');
    });
  }

  Future<void> _register() async {
    // Adres validasyonunu manuel yönetiyoruz (Form dışı widget).
    setState(() {
      _addressError =
          _pickedLocation == null ? 'Lütfen haritadan adres seç' : null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) return; // adres hatası zaten gösteriliyor

    if (!_acceptTerms) {
      AppToast.show(context, 'Lütfen kullanım koşullarını kabul et');
      return;
    }
    final ok = await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: '${_emailUsername.text.trim()}@$_emailDomain',
          phone: _phone.text.trim(),
          password: _password.text,
          address: _address.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      // Kayıt başarılı (token alındı). Haritadan seçilen adresi
      // gerçek adres sistemine kaydet (addresses tablosu).
      final loc = _pickedLocation!;
      await ref.read(addressProvider.notifier).add(
        UserAddress(
          id: '',
          type: AddressType.home,
          title: 'Ev',
          fullAddress: _address.text.trim(),
          district: loc.district,
          city: loc.city,
          lat: loc.latLng.latitude,
          lng: loc.latLng.longitude,
          isDefault: true,
        ),
      );
      if (!mounted) return;
      // İstersen OTP doğrulamaya da gidebilirsin; şimdilik doğrudan ana sayfaya geçiyoruz.
      context.go(AppRoutes.home);
    } else {
      final error = ref.read(authProvider).error;
      AppToast.show(context, error ?? 'Kayıt başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Oluştur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aramıza katıl', style: AppTypography.headlineLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('Birkaç adımda hesabını oluştur',
                    style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: 'Ad Soyad',
                  hint: 'Adın ve soyadın',
                  controller: _name,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ad soyad gerekli' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Telefon',
                  hint: '5XX XXX XX XX',
                  controller: _phone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.length < 10) ? 'Geçerli bir numara gir' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E-posta', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _emailUsername,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'kullaniciadi',
                              prefixIcon: const Icon(Icons.mail_outline_rounded,
                                  color: AppColors.softGray, size: 22),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'E-posta gerekli' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text('@', style: AppTypography.bodyLarge),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _emailDomain,
                                isExpanded: true,
                                items: const [
                                  'gmail.com',
                                  'hotmail.com',
                                  'outlook.com',
                                  'icloud.com',
                                  'yahoo.com',
                                ]
                                    .map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d,
                                              style: AppTypography.bodyMedium),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _emailDomain = v ?? _emailDomain),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Şifre',
                  hint: 'En az 6 karakter',
                  controller: _password,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Teslimat Adresi — haritadan seçilir ──────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teslimat Adresi',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickLocation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: _pickedLocation != null
                                ? AppColors.primary
                                : AppColors.border,
                            width: _pickedLocation != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pickedLocation != null
                                  ? Icons.location_on_rounded
                                  : Icons.add_location_alt_outlined,
                              color: _pickedLocation != null
                                  ? AppColors.primary
                                  : AppColors.softGray,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _pickedLocation != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _address.text,
                                          style: AppTypography.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Değiştirmek için dokun',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                                  color: AppColors.primary),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Haritadan konum seç',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.softGray),
                                    ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.softGray, size: 20),
                          ],
                        ),
                      ),
                    ),
                    // Validasyon hatası göstergesi
                    if (_addressError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _addressError!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onChanged: (v) =>
                          setState(() => _acceptTerms = v ?? false),
                    ),
                    Expanded(
                      child: Text('Kullanım koşullarını ve gizlilik politikasını kabul ediyorum',
                          style: AppTypography.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: 'Devam Et',
                  variant: AppButtonVariant.gradient,
                  loading: loading,
                  onPressed: _register,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Zaten hesabın var mı? ',
                          style: AppTypography.bodyMedium),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Giriş yap',
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
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
