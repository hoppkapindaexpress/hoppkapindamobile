import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/store.dart';
import '../../services/providers.dart';
import '../../widgets/widgets.dart';
import '../cart/cart_provider.dart';
import '../profile/favorites_provider.dart';
import 'product_options_sheet.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  const RestaurantDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildTabs(List<Product> products) {
    final groups = <String>['Popüler Lezzetler'];
    for (final p in products) {

    }
    if (groups.length != _groups.length) {
      final old = _tabController;
      final next = TabController(length: groups.length, vsync: this);
      setState(() {
        _groups = groups;
        _tabController = next;
      });
      old.dispose();
    } else {
      _groups = groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeProvider(widget.id));
    final productsAsync = ref.watch(storeProductsProvider(widget.id));
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: storeAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorView(),
        data: (store) {
          final isFav = favorites.contains(store.id);
          return productsAsync.when(
            loading: () => _body(context, store, isFav, [], loading: true),
            error: (e, _) => _body(context, store, isFav, []),
            data: (products) {
              _rebuildTabs(products);
              return _body(context, store, isFav, products);
            },
          );
        },
      ),
      floatingActionButton: _cartFab(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _body(BuildContext context, Store store, bool isFav,
      List<Product> products,
      {bool loading = false}) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // ── Kapak ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          leading: _iconBtn(Icons.arrow_back_ios_new_rounded, () => context.pop()),
          actions: [
            _iconBtn(Icons.search_rounded, () {}),
            const SizedBox(width: 8),
            _iconBtn(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              () => ref.read(favoritesProvider.notifier).toggle(store.id),
              color: isFav ? AppColors.secondary : Colors.white,
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.more_vert_rounded, () {}),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Görsel
                store.imageUrl != null && store.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: store.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary,
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white54, size: 72),
                        ),
                      )
                    : Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white54, size: 72),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Mağaza Bilgileri ───────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puan + mesafe + saat
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${store.reviewCount}+ yorum',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text('•',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Text(
                      store.type.label,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Mağaza adı
                Text(store.name, style: AppTypography.displayMedium),
                const SizedBox(height: 12),
                // Info chips
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _infoChip(
                        Icons.delivery_dining_rounded,
                        store.deliveryTimeLabel,
                        'Teslimat',
                        AppColors.primary,
                        border: false,
                      ),
                      _divider(),
                      _infoChip(
                        Icons.shopping_bag_outlined,
                        'Min ${store.minOrder.toStringAsFixed(0)} TL',
                        'Min Tutar',
                        AppColors.textDark,
                        border: false,
                      ),
                      _divider(),
                      GestureDetector(
                        onTap: () {},
                        child: _infoChip(
                          Icons.reviews_outlined,
                          '${store.reviewCount}',
                          'Yorumlar',
                          AppColors.textDark,
                          border: false,
                          trailing: const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Ücretsiz teslimat banner
                if (store.deliveryFee == 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Siparişiniz restoranın kuryesi tarafından hızlı ve sıcak olarak kapınıza teslim edilir.',
                            style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Ödeme tipi
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Banka & Kredi Kartı',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        // ── Tab Bar ────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            groups: _groups.isEmpty ? ['Menü'] : _groups,
          ),
        ),
      ],

      // ── Ürün Listesi ──────────────────────────────────────────
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _productListView(products)
              : TabBarView(
                  controller: _tabController,
                  children: _groups.map((group) {
                    final grouped = group == 'Popüler Lezzetler'
                        ? products
                        : products
                            .where((p) => true)
                            .toList();
                    return _productListView(grouped);
                  }).toList(),
                ),
    );
  }

  Widget _productListView(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Ürün bulunamadı'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: products.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${_groups.isEmpty ? "Menü" : (_groups.isNotEmpty ? _groups[_tabController.index] : "Menü")} (${products.length} Ürün)',
              style: AppTypography.titleLarge,
            ),
          );
        }
        return _productTile(products[i - 1]);
      },
    );
  }

  Widget _productTile(Product p) {
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol: isim + açıklama + fiyat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700)),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (p.options.isEmpty) {
                            ref.read(cartProvider.notifier).add(p);
                            AppToast.success(
                                context, '${p.name} sepete eklendi');
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  ProductOptionsSheet(product: p),
                            );
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${p.price.toStringAsFixed(0)} TL',
                        style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Sağ: görsel
            if (p.imageUrl != null && p.imageUrl!.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: p.imageUrl!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.fastfood_rounded,
                        color: AppColors.softGray),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String value,
    String label,
    Color color, {
    bool border = true,
    Widget? trailing,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                if (trailing != null) ...[
                  const SizedBox(width: 2),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            Text(label,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 50, color: const Color(0xFFEEEEEE));
  }

  Widget _cartFab() {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding),
      child: FloatingCartButton(
        itemCount: cart.itemCount,
        total: cart.total,
        onTap: () => context.push('/cart'),
      ),
    );
  }

  Widget _errorView() => EmptyState(
        title: 'Mağaza yüklenemedi',
        message: 'Bağlantını kontrol edip tekrar dene.',
        icon: Icons.error_outline_rounded,
        action: AppButton(
          label: 'Geri dön',
          expanded: false,
          onPressed: () => context.pop(),
        ),
      );
}

// ── Tab Bar Delegate ──────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(
      {required this.tabController, required this.groups});
  final TabController tabController;
  final List<String> groups;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: AppColors.textDark,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 14),
        indicatorColor: AppColors.textDark,
        indicatorWeight: 2.5,
        tabs: groups.map((g) => Tab(text: g)).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.groups != groups;
}
