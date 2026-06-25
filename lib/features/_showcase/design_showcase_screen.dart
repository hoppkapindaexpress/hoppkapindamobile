import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme_provider.dart';
import '../../widgets/widgets.dart';

/// Faz 1 tasarım sistemi vitrini.
///
/// Tema, tipografi ve tüm reusable widget'ları tek ekranda gösterir.
/// Geliştirme sırasında bileşenleri hızlı test etmek için kullanılır;
/// üretimde Home ekranı ile değiştirilecek.
class DesignShowcaseScreen extends ConsumerStatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  ConsumerState<DesignShowcaseScreen> createState() =>
      _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends ConsumerState<DesignShowcaseScreen> {
  int _navIndex = 0;
  int _selectedChip = 0;
  int _cartCount = 0;
  double _cartTotal = 0;
  bool _loadingDemo = false;

  void _addToCart(double price) {
    setState(() {
      _cartCount++;
      _cartTotal += price;
    });
    AppToast.success(context, 'Ürün sepete eklendi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('Hopp Kapında',
                  style: AppTypography.headlineMedium),
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            sliver: SliverList.list(children: [
              const AppSearchBar(readOnly: true),
              const SizedBox(height: AppSpacing.xl),

              _section('Kategoriler'),
              Row(
                children: [
                  Expanded(
                    child: CategoryCard(
                      title: 'Yemek',
                      subtitle: '1200+ restoran',
                      icon: Icons.restaurant_rounded,
                      gradient: AppColors.brandGradient,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CategoryCard(
                      title: 'Market',
                      subtitle: '20 dk teslimat',
                      icon: Icons.shopping_cart_rounded,
                      gradient: AppColors.warmGradient,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CategoryCard(
                title: 'Tatlı',
                subtitle: 'Tatlı krizine birebir',
                icon: Icons.icecream_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFF5A00D6)],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Filtreler (Chip)'),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < _filters.length; i++)
                    AppChip(
                      label: _filters[i],
                      selected: _selectedChip == i,
                      onTap: () => setState(() => _selectedChip = i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Kampanya Banner'),
              OfferBanner(
                title: 'İlk siparişe %40',
                subtitle: 'HOPP40 kodu ile geçerli',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Mağaza Kartları'),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) => StoreCard(
                    name: _stores[i],
                    imageUrl: '',
                    rating: 4.5 + i * 0.1,
                    deliveryTime: '${20 + i * 5} dk',
                    tags: const ['Burger', 'Fast Food'],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Ürün Kartları (Sepete ekle → bounce)'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.74,
                children: [
                  for (var i = 0; i < _products.length; i++)
                    ProductCard(
                      name: _products[i].$1,
                      description: _products[i].$2,
                      price: _products[i].$3,
                      oldPrice: i == 0 ? 89.90 : null,
                      onAdd: () => _addToCart(_products[i].$3),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Butonlar'),
              const AppButton(label: 'Primary (Gradient)', variant: AppButtonVariant.gradient),
              const SizedBox(height: AppSpacing.sm),
              const AppButton(
                  label: 'Secondary',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.bolt_rounded),
              const SizedBox(height: AppSpacing.sm),
              const AppButton(label: 'Outline', variant: AppButtonVariant.outline),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Yükleniyor demosu',
                variant: AppButtonVariant.ghost,
                loading: _loadingDemo,
                onPressed: () async {
                  setState(() => _loadingDemo = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _loadingDemo = false);
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Yükleme İskeleti (Skeleton)'),
              Row(
                children: const [
                  Expanded(child: ProductCardSkeleton()),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: ProductCardSkeleton()),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _section('Boş Durum (Empty State)'),
              SizedBox(
                height: 280,
                child: EmptyState(
                  title: 'Henüz sipariş yok',
                  message: 'İlk siparişini ver, kapına gelsin.',
                  icon: Icons.receipt_long_rounded,
                  action: AppButton(
                    label: 'Keşfetmeye başla',
                    expanded: false,
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),

      // Floating cart — ürün eklendiğinde belirir.
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: FloatingCartButton(
          itemCount: _cartCount,
          total: _cartTotal,
          onTap: () => AppToast.show(context, 'Sepet ekranı Faz 2\'de'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Ana Sayfa'),
          AppNavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Ara'),
          AppNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Siparişler'),
          AppNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(title, style: AppTypography.headlineSmall),
      );

  static const _filters = ['Tümü', 'Hızlı Teslimat', 'İndirimli', 'Yeni', 'Çok Satan'];
  static const _stores = ['Burger House', 'Pizza Roma', 'Sushi Master'];
  static const _products = <(String, String, double)>[
    ('Cheeseburger Menü', 'Patates + İçecek', 69.90),
    ('Margherita Pizza', 'Orta boy', 119.50),
    ('Tiramisu', 'Ev yapımı', 54.00),
    ('Latte', 'Sıcak / Soğuk', 42.00),
  ];
}
