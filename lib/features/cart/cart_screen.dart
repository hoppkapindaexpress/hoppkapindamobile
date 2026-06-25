import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_item.dart';
import '../../widgets/widgets.dart';
import '../address/address_provider.dart';
import '../address/location_picker_screen.dart';
import '../auth/auth_provider.dart';
import '../../routes/app_router.dart';
import '../auth/auth_service.dart';
import '../orders/order_service.dart';
import 'coupon_service.dart';
import '../orders/order_provider.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _placingOrder = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final subtotal = ref.read(cartProvider).subtotal;
    final coupon = await CouponService.validate(code, subtotal);
    if (!mounted) return;
    if (coupon != null) {
      ref.read(cartProvider.notifier).setCoupon(coupon);
      AppToast.success(context, '$code kuponu uygulandı');
      _couponController.clear();
      FocusScope.of(context).unfocus();
    } else {
      AppToast.show(context, 'Geçersiz kupon kodu veya yetersiz tutar');
    }
  }

  /// "Siparişi Tamamla"ya basınca bottom sheet açılır.
  Future<void> _openCheckoutSheet(CartState cart) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
        child: _CheckoutSheet(
          cart: cart,
          onOrderPlaced: () {
            ref.read(cartProvider.notifier).clear();
            ref.invalidate(ordersProvider);
            if (mounted) {
              AppToast.success(context, 'Siparişin alındı! 🎉');
              context.go('/home');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                AppToast.show(context, 'Sepet temizlendi');
              },
              child: Text('Temizle',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty ? _emptyCart() : _cartBody(cart),
      bottomNavigationBar:
          cart.isEmpty ? null : _checkoutBar(cart),
    );
  }

  Widget _emptyCart() => EmptyState(
        title: 'Sepetin boş',
        message: 'Hadi lezzetli bir şeyler ekleyelim.',
        icon: Icons.shopping_bag_outlined,
        action: AppButton(
          label: 'Keşfetmeye başla',
          expanded: false,
          onPressed: () => context.go('/home'),
        ),
      );

  Widget _cartBody(CartState cart) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ...cart.items.map(_cartTile),
        const SizedBox(height: AppSpacing.lg),
        _couponSection(cart),
        const SizedBox(height: AppSpacing.lg),
        _summary(cart),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _cartTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.fastfood_rounded,
                color: AppColors.softGray, size: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text('₺${(item.lineTotal / item.quantity).toStringAsFixed(2)}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          _quantityStepper(item),
        ],
      ),
    );
  }

  Widget _quantityStepper(CartItem item) {
    final notifier = ref.read(cartProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        children: [
          _stepBtn(
            icon: item.quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: () => notifier.decrement(item.product.id),
          ),
          SizedBox(
            width: 28,
            child: Text('${item.quantity}',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium),
          ),
          _stepBtn(
            icon: Icons.add_rounded,
            onTap: () => notifier.add(item.product),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: highlight ? AppColors.brandGradient : null,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: highlight ? Colors.white : AppColors.textDark),
      ),
    );
  }

  Widget _couponSection(CartState cart) {
    if (cart.coupon != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdAll,
          border:
              Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('${cart.coupon!.code} uygulandı',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.success)),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(cartProvider.notifier).removeCoupon(),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.success, size: 20),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _couponController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Kupon kodu (ör. HOPP40)',
              prefixIcon: Icon(Icons.local_offer_outlined,
                  color: AppColors.softGray, size: 20),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: 'Uygula',
          variant: AppButtonVariant.ghost,
          expanded: false,
          height: 54,
          onPressed: _applyCoupon,
        ),
      ],
    );
  }

  Widget _summary(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _row('Ara toplam', cart.subtotal),
          if (cart.discount > 0)
            _row('İndirim', -cart.discount, color: AppColors.success),
          _row('Teslimat', cart.deliveryFee,
              freeLabel: cart.deliveryFee == 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _row('Toplam', cart.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _row(String label, double amount,
      {bool isTotal = false, bool freeLabel = false, Color? color}) {
    final style =
        isTotal ? AppTypography.headlineSmall : AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            freeLabel
                ? 'Ücretsiz'
                : '${amount < 0 ? '-' : ''}₺${amount.abs().toStringAsFixed(2)}',
            style: style.copyWith(
              color: freeLabel
                  ? AppColors.success
                  : (color ?? (isTotal ? AppColors.primary : null)),
              fontWeight: isTotal ? FontWeight.w800 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutBar(CartState cart) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.md, AppSpacing.screenPadding, AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toplam', style: AppTypography.bodySmall),
                Text('₺${cart.total.toStringAsFixed(2)}',
                    style: AppTypography.headlineMedium
                        .copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: isLoggedIn
                  ? AppButton(
                      label: 'Siparişi Tamamla',
                      variant: AppButtonVariant.gradient,
                      icon: Icons.arrow_forward_rounded,
                      loading: _placingOrder,
                      onPressed: () => _openCheckoutSheet(cart),
                    )
                  : AppButton(
                      label: 'Giriş Yap',
                      variant: AppButtonVariant.gradient,
                      icon: Icons.login_rounded,
                      onPressed: () => context.push(AppRoutes.login),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CHECKOUT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet({
    required this.cart,
    required this.onOrderPlaced,
  });

  final CartState cart;
  final VoidCallback onOrderPlaced;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _courierNoteCtrl = TextEditingController();

  UserAddress? _selectedAddress;
  bool _placing = false;

  /// Ödeme yöntemi — web'deki CartDrawer ile aynı mantık.
  /// _paymentGroup: 'kapida' | 'transfer' | 'card'
  /// _kapidaSubOption: 'cash' | 'pos' (sadece _paymentGroup == 'kapida' iken anlamlı)
  String _paymentGroup = 'kapida';
  String _kapidaSubOption = 'cash';

  /// Backend'e gönderilecek nihai payment_method değeri.
  String get _paymentMethod => switch (_paymentGroup) {
        'kapida' => _kapidaSubOption, // 'cash' | 'pos'
        'transfer' => 'transfer',
        'card' => 'card',
        _ => 'cash',
      };

  @override
  void initState() {
    super.initState();

    // Kayıtlı kullanıcının telefonunu doldur.
    final phone = ref.read(authProvider).user?.phone ?? '';
    if (phone.isNotEmpty) _phoneCtrl.text = phone;

    // Varsayılan adresi seç.
    final addresses = ref.read(addressProvider);
    _selectedAddress = addresses.where((a) => a.isDefault).firstOrNull
        ?? (addresses.isNotEmpty ? addresses.first : null);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _courierNoteCtrl.dispose();
    super.dispose();
  }

  bool get _isGuest => !ref.read(authProvider).isLoggedIn;

  Future<void> _submit() async {
    // ── Ad/Soyad (misafir) ──────────────────────────────────────
    String? guestName;
    if (_isGuest) {
      final fn = _firstNameCtrl.text.trim();
      final ln = _lastNameCtrl.text.trim();
      if (fn.isEmpty || ln.isEmpty) {
        _toast('Lütfen adınızı ve soyadınızı girin');
        return;
      }
      guestName = '$fn $ln';
    }

    // ── Adres ───────────────────────────────────────────────────
    if (_selectedAddress == null) {
      _toast('Lütfen bir teslimat adresi seçin');
      return;
    }

    // ── Telefon ─────────────────────────────────────────────────
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _toast('Lütfen telefon numaranızı girin');
      return;
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _toast('Geçerli bir telefon numarası girin');
      return;
    }

    setState(() => _placing = true);
    try {
      final addr = _selectedAddress!;
      final fullAddress =
          '${addr.fullAddress}, ${addr.district}, ${addr.city}';
      final directions = [
        if (addr.doorNo?.isNotEmpty == true) 'Kapı No: ${addr.doorNo}',
        if (addr.note?.isNotEmpty == true) addr.note!,
      ].join(' · ');

      await OrderService.createOrder(
        storeId: widget.cart.items.first.product.storeId,
        items: widget.cart.items,
        deliveryAddress: fullAddress,
        phone: phone,
        guestName: guestName,
        paymentMethod: _paymentMethod,
        address: {
          'label': addr.title.isNotEmpty ? addr.title : addr.type.label,
          'full_address': fullAddress,
          'floor': addr.floor,
          'directions': directions.isEmpty ? null : directions,
          'lat': addr.lat,
          'lng': addr.lng,
        },
        couponCode: widget.cart.coupon?.code,
        courierNote: _courierNoteCtrl.text.trim().isEmpty
            ? null
            : _courierNoteCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // sheet'i kapat
      widget.onOrderPlaced();
    } catch (e) {
      if (mounted) _toast(OrderService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  /// Harita picker açarak seçili adresin konumunu günceller.
  Future<void> _rePickLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result == null || _selectedAddress == null) return;
    final updated = _selectedAddress!.copyWith(
      fullAddress: result.address,
      district: result.district,
      city: result.city,
      lat: result.latLng.latitude,
      lng: result.latLng.longitude,
    );
    await ref.read(addressProvider.notifier).update(updated);
    setState(() => _selectedAddress = updated);
  }

  void _toast(String msg) => AppToast.show(context, msg);

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressProvider);
    final isGuest   = _isGuest;

    return ClipRRect(
      borderRadius: AppRadius.xlAll,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: AppRadius.xlAll,
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Başlık + kapat butonu ────────────────────────
              Row(
                children: [
                  Text('Sipariş Bilgileri',
                      style: AppTypography.headlineSmall),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.softGray),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

            // ── Misafir: Ad & Soyad ──────────────────────────────
            if (isGuest) ...[
              _sectionLabel(Icons.person_outline_rounded,
                  'İletişim Bilgileri'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: _field(_firstNameCtrl, 'Ad')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _field(_lastNameCtrl, 'Soyad')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Teslimat Adresi ──────────────────────────────────
            Row(
              children: [
                _sectionLabel(
                    Icons.location_on_rounded, 'Teslimat Adresi'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(
                      const Duration(milliseconds: 150),
                      () => Navigator.of(context, rootNavigator: true)
                          .pushNamed('/addresses'),
                    );
                  },
                  child: Text('Adres Ekle',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (addresses.isEmpty)
              _noAddressTile()
            else ...[
              _addressDropdown(addresses),
              if (_selectedAddress != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _rePickBtn(),
              ],
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Ödeme Yöntemi ────────────────────────────────────
            _paymentMethodSection(),

            const SizedBox(height: AppSpacing.lg),

            // ── Kurye Notu ───────────────────────────────────────
            _sectionLabel(Icons.edit_note_rounded, 'Kurye Notu (isteğe bağlı)'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _courierNoteCtrl,
              'Örn: Kapı kodu 1234, zil çalışmıyor',
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Telefon ──────────────────────────────────────────
            _sectionLabel(Icons.phone_rounded, 'Telefon Numarası'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _phoneCtrl,
              '0 5XX XXX XX XX',
              keyboardType: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d\s\+\-\(\)]')),
                LengthLimitingTextInputFormatter(15),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kurye seni bu numara üzerinden arayabilir.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.softGray),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Onayla butonu ────────────────────────────────────
            AppButton(
              label: 'Siparişi Onayla',
              variant: AppButtonVariant.gradient,
              icon: Icons.check_rounded,
              loading: _placing,
              onPressed: _submit,
            ),
          ],
          ),
        ),
      ),
    );
  }

  // ── Yardımcı widget'lar ───────────────────────────────────────

  Widget _paymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.wallet_rounded, 'Ödeme Yöntemi'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _paymentCard(
                group: 'kapida',
                icon: Icons.delivery_dining_rounded,
                label: 'Kapıda Ödeme',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _paymentCard(
                group: 'transfer',
                icon: Icons.account_balance_rounded,
                label: 'Havale / EFT',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _paymentCard(
                group: 'card',
                icon: Icons.credit_card_rounded,
                label: 'Kredi Kartı',
                disabled: true,
                badge: 'YAKINDA',
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _paymentGroup == 'kapida'
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: _subOptionChip(
                          value: 'cash',
                          icon: Icons.payments_rounded,
                          label: 'Nakit',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _subOptionChip(
                          value: 'pos',
                          icon: Icons.point_of_sale_rounded,
                          label: 'POS Cihazı',
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _paymentCard({
    required String group,
    required IconData icon,
    required String label,
    bool disabled = false,
    String? badge,
  }) {
    final selected = _paymentGroup == group;
    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _paymentGroup = group),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.softGray.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon,
                      size: 22,
                      color:
                          selected ? AppColors.primary : AppColors.softGray),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge,
                            style: const TextStyle(
                                fontSize: 7,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTypography.labelSmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textDark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subOptionChip({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final selected = _kapidaSubOption == value;
    return GestureDetector(
      onTap: () => setState(() => _kapidaSubOption = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.softGray),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? color : AppColors.textDark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 5),
        Text(text, style: AppTypography.titleSmall),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(
              color: AppColors.softGray.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _noAddressTile() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 150),
            () => Navigator.of(context, rootNavigator: true)
                .pushNamed('/addresses'));
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: AppRadius.mdAll,
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Sipariş için adres eklemelisin',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _addressDropdown(List<UserAddress> addresses) {
    final selected = _selectedAddress != null &&
            addresses.any((a) => a.id == _selectedAddress!.id)
        ? addresses.firstWhere((a) => a.id == _selectedAddress!.id)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.soft,
      ),
      child: DropdownButton<UserAddress>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text('Adres seçin',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.softGray)),
        items: addresses.map((a) {
          return DropdownMenuItem<UserAddress>(
            value: a,
            child: Row(
              children: [
                Text(a.type.icon,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.title,
                          style: AppTypography.labelMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(a.shortAddress,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.softGray),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (a.isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Varsayılan',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10)),
                  ),
              ],
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) => addresses.map((a) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              a.fullAddress,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (addr) => setState(() => _selectedAddress = addr),
      ),
    );
  }

  Widget _rePickBtn() {
    return GestureDetector(
      onTap: _rePickLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text('Konumu Tekrar Belirle',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
