import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../utils/feedback_sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/store.dart';
import '../../services/providers.dart';
import '../../widgets/widgets.dart';
import '../../routes/app_router.dart';
import '../cart/cart_provider.dart';
import '../restaurant/product_options_sheet.dart';
import '../address/address_provider.dart';
import '../notifications/notifications_provider.dart';
import '../profile/favorites_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
/// Seçilen kategori — 'all', 'restaurant', 'dessert', 'market'
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

/// Yemek alt kategorisi — 'Döner', 'Köfte', vb. null = hepsi
final selectedFoodCatProvider = StateProvider<String?>((ref) => null);

final selectedStoreProvider = StateProvider<String?>((ref) => null);

/// Ana sayfa — tasarım revizyonu (Faz 4 UI).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          // Aşağı çekince tüm Home verilerini tazele (admin değişiklikleri görünsün).
          ref.invalidate(campaignsProvider);
          ref.invalidate(allProductsProvider);
          ref.invalidate(storesProvider);
          // Tazelenen veriler gelene kadar kısa bekleme.
          await Future.wait([
            ref.read(campaignsProvider.future),
            ref.read(allProductsProvider.future),
            ref.read(storesProvider.future),
          ]).catchError((_) => <dynamic>[]);
        },
        child: CustomScrollView(
          slivers: [
          // ── Header ──────────────────────────────────────
          SliverToBoxAdapter(child: _Header()),

          // ── Hero Banner ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 0),
            sliver: SliverToBoxAdapter(child: _HeroBanner()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Büyük Kategori Kartları ───────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverToBoxAdapter(child: _CategoryRow()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Mutfaklar + Yemek Kategorileri ──────────────
          SliverToBoxAdapter(child: _MutfaklarHeader()),
          const SliverToBoxAdapter(child: _CategorySelectorWrapper()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── Yakındaki Mağazalar ──────────────────────────
          _SectionHeader(
              title: 'Yakındaki Mağazalar', actionLabel: 'Tümünü Gör'),
          _NearbyStores(),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── Popüler Ürünler ──────────────────────────────
          _SectionHeader(title: 'Popüler Ürünler'),
          _AllProducts(),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),


        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);
    final defaultAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.isNotEmpty ? addresses.first : _kEmptyAddress,
    );
    final hasAddress = addresses.isNotEmpty;
    final unread = ref.watch(unreadCountProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Satır 1: Teslimat adresi  +  Bildirim zili ──────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, AppSpacing.sm,
              AppSpacing.screenPadding, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol: Teslimat adresi
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddressPicker(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smAll,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Teslimat adresi',
                              style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          Row(
                            children: [
                              Text(
                                hasAddress
                                    ? defaultAddress.title
                                    : 'Adres ekle',
                                style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textDark),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textDark, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sağ: Bildirim zili
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: AppRadius.mdAll,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 24),
                      if (unread > 0)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).cardColor,
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    height: 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Satır 2: Logo — kendi satırında, tam ortada, kısıtsız ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: Image.asset(
              'assets/images/logo_hopp.png',
              // 660×225 oranı (2.933:1) → height 110 ⟹ width ≈ 323
              width: 323,
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  /// Kayıtlı hiç adres yokken fallback için boş sentinel.
  static final _kEmptyAddress = UserAddress(
    id: '',
    type: AddressType.home,
    title: 'Adres ekle',
    fullAddress: '',
    district: '',
    city: '',
  );

  /// Adres seçim bottom sheet'ini gösterir.
  void _showAddressPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _AddressPickerSheet(ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────
class _HeroBanner extends StatefulWidget {
  const _HeroBanner();

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF),
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/hero_banner_graphic.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 160, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Sen iste,\n',
                          style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: 'Hopp Kapında',
                          style: AppTypography.titleLarge.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text('Ihtiyacın olan her sey\nkapında!',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted, height: 1.4)),
                  ],
                ),
                ScaleTransition(
                  scale: _scale,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Text('Hemen Keşfet',
                          style: AppTypography.labelMedium.copyWith(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// KATEGORI SATIRI
// ─────────────────────────────────────────────────────────────────
class _CategoryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final categories = [
      _Cat(
        key: 'restaurant',
        title: 'Yemek',
        subtitle: 'Lezzetli yemekler',
        imagePath: 'assets/images/categories/yemek.png',
        bgColor: const Color(0xFFFFE5E5),
        accent: const Color(0xFFE53935),
      ),
      _Cat(
        key: 'dessert',
        title: 'Tatlı',
        subtitle: 'En tatlı anlar!',
        imagePath: 'assets/images/categories/tatli.png',
        bgColor: const Color(0xFFE8F5E9),
        accent: const Color(0xFF2E7D32),
      ),
      _Cat(
        key: 'market',
        title: 'Market',
        subtitle: 'Her sey kapında!',
        imagePath: 'assets/images/categories/market.png',
        bgColor: const Color(0xFFF3E5F5),
        accent: const Color(0xFF7B1FA2),
      ),
    ];

    return Row(
      children: categories
          .map((c) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: c == categories.last ? 0 : AppSpacing.sm),
                  child: _CategoryTile(
                    cat: c,
                    isSelected: selected == c.key,
                    onTap: () {
                      final notifier =
                          ref.read(selectedCategoryProvider.notifier);
                      notifier.state = selected == c.key ? 'all' : c.key;
                      ref.read(selectedFoodCatProvider.notifier).state = null;
                    },
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _Cat {
  final String key, title, subtitle, imagePath;
  final Color bgColor;
  final Color accent;
  const _Cat(
      {required this.key,
      required this.title,
      required this.subtitle,
      required this.imagePath,
      required this.bgColor,
      required this.accent});
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.isSelected,
    required this.onTap,
  });
  final _Cat cat;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: 182,
          decoration: BoxDecoration(
            color: cat.bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: cat.accent.withValues(alpha: isSelected ? 0.40 : 0.18),
                blurRadius: isSelected ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cat.accent,
                          cat.accent.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: cat.key == 'restaurant' ? 20 : 22,
                          height: cat.key == 'restaurant' ? 20 : 22,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00C853) : Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Color(0xFF00C853),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ] : [],
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.arrow_forward_rounded,
                            size: cat.key == 'restaurant' ? 11 : 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 48, left: 0, right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 16),
                    painter: _FlamaPainter(color: cat.accent),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Image.asset(
                    cat.imagePath,
                    height: 115,
                    fit: BoxFit.contain,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: cat.accent,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat.title.toUpperCase() + ' SEÇİLDİ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
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

class _FlamaPainter extends CustomPainter {
  final Color color;
  const _FlamaPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, 14)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_FlamaPainter old) => old.color != color;
}


// ─────────────────────────────────────────────────────────────────
class _MutfaklarHeader extends StatelessWidget {
  const _MutfaklarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mutfaklar', style: AppTypography.headlineSmall),
          Row(
            children: [
              GestureDetector(
                onTap: () => _CategorySelectorState.scrollLeftGlobal?.call(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A00D6).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF5A00D6), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _CategorySelectorState.scrollRightGlobal?.call(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A00D6).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF5A00D6), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySelectorWrapper extends StatelessWidget {
  const _CategorySelectorWrapper();
  @override
  Widget build(BuildContext context) => _CategorySelector();
}

class _CategorySelector extends ConsumerStatefulWidget {
  static const _allCats = [
    {'label': 'Döner',          'img': 'assets/images/categories/cat-doner.png'},
    {'label': 'Köfte',          'img': 'assets/images/categories/cat-kofte.png'},
    {'label': 'Kebap',          'img': 'assets/images/categories/cat-kebap.png'},
    {'label': 'Tavuk',          'img': 'assets/images/categories/cat-tavuk.png'},
    {'label': 'Hamburger',      'img': 'assets/images/categories/cat-hamburger.png'},
    {'label': 'Pizza',          'img': 'assets/images/categories/cat-pizza.png'},
    {'label': 'Pide & Lahmacun','img': 'assets/images/categories/cat-pide.png'},
    {'label': 'Çiğ Köfte',      'img': 'assets/images/categories/cat-cigkofte.png'},
    {'label': 'Tost',           'img': 'assets/images/categories/cat-tost.png'},
  ];

  static const _dessertCats = [
    {'label': 'Tatlı',          'img': 'assets/images/categories/cat-tatli.png'},
  ];

  static const _marketCats = [
    {'label': 'Dondurma',       'img': 'assets/images/categories/cat-dondurma.png'},
  ];

  @override
  ConsumerState<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<_CategorySelector> {
  final ScrollController _scrollController = ScrollController();


  static VoidCallback? scrollLeftGlobal;
  static VoidCallback? scrollRightGlobal;


  @override
  void initState() {
    super.initState();
    scrollLeftGlobal = _scrollLeft;
    scrollRightGlobal = _scrollRight;
  }

  @override
  void dispose() {
    scrollLeftGlobal = null;
    scrollRightGlobal = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 200).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 200).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedFoodCatProvider);
    final mainCat = ref.watch(selectedCategoryProvider);
    final cats = mainCat == 'dessert'
        ? _CategorySelector._dessertCats
        : mainCat == 'market'
            ? _CategorySelector._marketCats
            : _CategorySelector._allCats;

    return SizedBox(
      height: 114,
      child: Stack(
        children: [
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 18, AppSpacing.screenPadding, 4),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final label = cat['label']!;
              final img = cat['img']!;
              final isSelected = selected == label;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedFoodCatProvider.notifier).state =
                      isSelected ? null : label;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFF0E8FF) : Colors.white,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5A00D6) : const Color(0xFFE8E4F4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF5A00D6).withValues(alpha: 0.22)
                                    : Colors.black.withValues(alpha: 0.06),
                                blurRadius: isSelected ? 16 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          transform: isSelected
                              ? (Matrix4.identity()..translate(0.0, -4.0))
                              : Matrix4.identity(),
                          child: ClipOval(
                            child: Image.asset(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fastfood_rounded,
                                color: Color(0xFF5A00D6),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: -14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00C853),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                'SEÇİLDİ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF5A00D6) : const Color(0xFF1A1626),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ],
      ),
    );
  }
}

class _CatItem {
  final String key, label, imagePath;
  final Color color;
  const _CatItem(this.key, this.label, this.imagePath, this.color);
}

// SECTION HEADER
// ─────────────────────────────────────────────────────────────────
class _SectionHeader extends SliverToBoxAdapter {
  _SectionHeader({required String title, String? actionLabel})
      : super(
          child: Builder(builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0,
                  AppSpacing.screenPadding, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.headlineSmall),
                  if (actionLabel != null)
                    Row(
                      children: [
                        Text(actionLabel,
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.primary),
                      ],
                    ),
                ],
              ),
            );
          }),
        );
}

// ─────────────────────────────────────────────────────────────────
// TÜM ÜRÜNLER
// ─────────────────────────────────────────────────────────────────
class _AllProducts extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return SliverToBoxAdapter(
      child: productsAsync.when(
        loading: () => SizedBox(
          height: 480,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            itemCount: 3,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Column(
                children: const [
                  SizedBox(width: 160, child: ProductCardSkeleton()),
                  SizedBox(height: AppSpacing.sm),
                  SizedBox(width: 160, child: ProductCardSkeleton()),
                ],
              ),
            ),
          ),
        ),
        error: (e, _) => const SizedBox.shrink(),
        data: (products) {
          // Kategori filtresi
          final cat = ref.watch(selectedCategoryProvider);
          final foodCat = ref.watch(selectedFoodCatProvider);
          final selectedStore = ref.watch(selectedStoreProvider);
          final storeList = ref.watch(storesProvider).maybeWhen(
                data: (s) => s, orElse: () => <Store>[]);

          List<dynamic> visibleProducts = cat == 'all'
              ? products
              : products.where((p) {
                  final store = storeList.where((s) => s.id == p.storeId);
                  if (store.isEmpty) return false;
                  return store.first.type.name == cat;
                }).toList();

          if (selectedStore != null) {
            visibleProducts = visibleProducts
                .where((p) => p.storeId == selectedStore)
                .toList();
          }

          if (foodCat != null) {
            final catLower = foodCat.toLowerCase();
            visibleProducts = visibleProducts.where((p) {
              final nameLower = p.name.toLowerCase();
              if (catLower == 'köfte') {
                return nameLower.contains('köfte') && !nameLower.contains('çiğ');
              } else if (catLower == 'çiğ köfte') {
                return nameLower.contains('çiğ');
              } else if (catLower == 'tatlı') {
                return (p.description ?? '').toLowerCase().contains('tatlı');
              } else {
                return nameLower.contains(catLower) ||
                    (p.description ?? '').toLowerCase().contains(catLower);
              }
            }).toList();
          }
          if (visibleProducts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Henüz ürün eklenmemiş'),
              ),
            );
          }

          const cardW = 160.0;
          const cardH = 230.0;
          const gap = 10.0;

          return SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              itemCount: visibleProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: gap),
              itemBuilder: (_, i) {
                final p = visibleProducts[i];
                return SizedBox(
                  width: cardW,
                  child: ProductCard(
                    productId: p.id,
                    name: p.name,
                    price: p.price,
                    oldPrice: p.oldPrice,
                    imageUrl: p.imageUrl,
                    storeName: p.storeName,
                    rating: p.rating,
                    reviewCount: p.reviewCount,
                    product: p,
                    onTap: () => context.push('/product/${p.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// YAKINDAKI MAĞAZALAR
// ─────────────────────────────────────────────────────────────────
class _NearbyStores extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const pad = AppSpacing.screenPadding;
          const gap = 12.0;
          const visible = 2.8;

          final available = constraints.maxWidth - pad * 2;
          final cardW =
              ((available - gap * (visible - 1)) / visible).clamp(120.0, 200.0).toDouble();
          final imageH = cardW * 0.75;
          final cardH = imageH + 95;

          return SizedBox(
            height: cardH,
            child: storesAsync.when(
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: pad),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (_, __) => SizedBox(
                  width: cardW,
                  child: SkeletonBox(height: cardH, radius: AppRadius.lg),
                ),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (stores) {
                final cat = ref.watch(selectedCategoryProvider);
                final filtered = cat == 'all'
                    ? stores
                    : stores.where((s) => s.type.name == cat).toList();
                if (filtered.isEmpty) return const SizedBox.shrink();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: pad),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(width: gap),
                  itemBuilder: (_, i) => SizedBox(
                    width: cardW,
                    child: _StoreCard(
                        store: filtered[i],
                        width: cardW,
                        imageHeight: imageH),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Yatay şeritte tek mağaza — büyük kart (görsel + puan + favori + bilgi).
class _StoreCard extends ConsumerWidget {
  const _StoreCard({
    required this.store,
    required this.width,
    required this.imageHeight,
  });
  final Store store;
  final double width;
  final double imageHeight;

  /// Yorum sayısını "70+" gibi yuvarlar.
  String _countLabel(int c) => c >= 10 ? '${(c ~/ 10) * 10}+' : '$c';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final selectedStore = ref.watch(selectedStoreProvider);
    final isStoreSelected = selectedStore == store.id;
    final isFav = favorites.contains(store.id);
    final hasImage = store.imageUrl != null && store.imageUrl!.isNotEmpty;
    final trimmed = store.name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    // Görsel yoksa/yüklenemezse baş harf placeholder'ı.
    Widget fallback() => Container(
          color: AppColors.primary.withValues(alpha: 0.07),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: imageHeight * 0.4,
            ),
          ),
        );

    return GestureDetector(
      onTap: () => context.push('/restaurant/${store.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
          border: isStoreSelected
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Görsel + üzerindeki rozetler ─────────────
            SizedBox(
              width: width,
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? CachedNetworkImage(imageUrl:
                          store.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => fallback(),
                        )
                      : fallback(),



                  // Favori kalbi (sağ üst)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(store.id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 13,
                          color: isFav
                              ? AppColors.secondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bilgiler ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Min ₺${store.minOrder.toStringAsFixed(0)}  •  ${store.type.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall
                        .copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        store.deliveryTimeLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${store.rating.toStringAsFixed(1)} (${_countLabel(store.reviewCount)})',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ADRES SEÇİM BOTTOM SHEET (Ana Sayfa Header için)
// ─────────────────────────────────────────────────────────────────

/// Header'daki teslimat adresi alanına tıklandığında açılan bottom sheet.
///
/// Kayıtlı adresleri listeler; kullanıcı bir adrese dokunduğunda o adresi
/// varsayılan yapar ve sheet kapanır. "Tüm Adresler" butonu tam
/// AddressScreen'e yönlendirir.
class _AddressPickerSheet extends ConsumerWidget {
  const _AddressPickerSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final addresses = innerRef.watch(addressProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // Şeffaf frosted-glass efekti
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık satırı ────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Teslimat Adresi',
                          style: AppTypography.titleLarge),
                    ),
                    // Kapat butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Adres listesi veya boş durum ─────────────────
                if (addresses.isEmpty)
                  _EmptyAddressHint(
                    onAddTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.addresses);
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final a = addresses[i];
                      return _PickerAddressTile(
                        address: a,
                        onTap: () {
                          innerRef
                              .read(addressProvider.notifier)
                              .setDefault(a.id);
                          Navigator.pop(context);
                          AppToast.success(
                              context, '${a.title} adresi seçildi');
                        },
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // ── Aksiyonlar ───────────────────────────────────
                Row(
                  children: [
                    // Tüm Adresler (ghost)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.addresses);
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: AppRadius.smAll,
                          ),
                          alignment: Alignment.center,
                          child: Text('Tüm Adresler',
                              style: AppTypography.labelMedium
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Yeni Adres (dolu)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.addresses);
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.smAll,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text('Yeni Adres',
                                  style: AppTypography.labelMedium
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picker'daki tek adres satırı.
class _PickerAddressTile extends StatelessWidget {
  const _PickerAddressTile({required this.address, required this.onTap});
  final UserAddress address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = address.isDefault;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            // Tip ikonu
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.smAll,
              ),
              child: Center(
                child: Text(address.type.icon,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Başlık + kısa adres
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.title,
                      style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(address.shortAddress,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Seçili işareti
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Hiç adres yokken gösterilen yönlendirici widget.
class _EmptyAddressHint extends StatelessWidget {
  const _EmptyAddressHint({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.location_off_rounded,
              size: 48, color: AppColors.softGray),
          const SizedBox(height: AppSpacing.sm),
          Text('Henüz adres eklemediniz',
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Sipariş verebilmek için adres ekleyin.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
