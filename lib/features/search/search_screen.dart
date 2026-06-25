import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/store.dart';
import '../../services/providers.dart';
import '../../widgets/widgets.dart';

// ============================================================
//  State
// ============================================================

/// Son aramalar provider — SharedPreferences'ta saklanır.
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
        (ref) => RecentSearchesNotifier());

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _load();
  }

  static const _key = 'recent_searches';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [query, ...state.where((s) => s != query)].take(8).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> remove(String query) async {
    state = state.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ============================================================
//  Ekran
// ============================================================

/// Arama ekranı — mağaza ve ürün sonuçlarını gerçek API verisiyle filtreler.
///
/// Debounce: 350ms sonra arama tetiklenir, gereksiz render önlenir.
/// Filtreler: Tümü / Yemek / Market / Tatlı
/// Son aramalar: SharedPreferences'a kaydedilir, chip'ler halinde gösterilir.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  String _query = '';
  StoreType? _typeFilter; // null = Tümü

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _query = _controller.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submitQuery(String q) {
    if (q.trim().isEmpty) return;
    setState(() => _query = q.trim());
    ref.read(recentSearchesProvider.notifier).add(q.trim());
    _focus.unfocus();
  }

  void _fillQuery(String q) {
    _controller.text = q;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: q.length));
    _submitQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // ---------- Arama çubuğu ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, AppSpacing.md,
                AppSpacing.screenPadding, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitQuery,
                    style: AppTypography.titleMedium,
                    decoration: InputDecoration(
                      hintText: 'Restoran, market veya ürün ara…',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.softGray),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.softGray),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide:
                            const BorderSide(color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- Filtre chip'leri ----------
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Tümü',
                  selected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final t in StoreType.values) ...[
                  _FilterChip(
                    label: t.label,
                    selected: _typeFilter == t,
                    onTap: () => setState(
                        () => _typeFilter = _typeFilter == t ? null : t),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ---------- İçerik ----------
          Expanded(
            child: _query.isEmpty
                ? _EmptyQueryView(onChipTap: _fillQuery)
                : _SearchResults(
                    query: _query,
                    typeFilter: _typeFilter,
                    onStoreTap: (store) {
                      ref
                          .read(recentSearchesProvider.notifier)
                          .add(store.name);
                      context.push('/restaurant/${store.id}');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Boş sorgu — son aramalar + kategoriler
// ============================================================

class _EmptyQueryView extends ConsumerWidget {
  const _EmptyQueryView({required this.onChipTap});
  final void Function(String) onChipTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSearchesProvider);
    final storesAsync = ref.watch(storesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Son aramalar
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Son Aramalar', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                child: Text('Temizle',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: recents
                .map((s) => ActionChip(
                      avatar: const Icon(Icons.history_rounded,
                          size: 16, color: AppColors.textMuted),
                      label: Text(s, style: AppTypography.bodySmall),
                      backgroundColor: Theme.of(context).cardColor,
                      side:
                          const BorderSide(color: AppColors.border, width: 1),
                      onPressed: () => onChipTap(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Tüm Mağazalar
        Text('Tüm Mağazalar', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        storesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (stores) {
            // Ürünü olan mağazalar önce, olmayanlar sona
            final withProducts = stores.where((s) =>
                ref.watch(storeProductsProvider(s.id)).maybeWhen(
                      data: (p) => p.isNotEmpty,
                      orElse: () => true,
                    )).toList();
            final withoutProducts = stores.where((s) =>
                ref.watch(storeProductsProvider(s.id)).maybeWhen(
                      data: (p) => p.isEmpty,
                      orElse: () => false,
                    )).toList();
            final sorted = [...withProducts, ...withoutProducts];
            return Column(
              children: sorted
                  .map((s) => _AllStoreTile(
                        store: s,
                        onTap: () {
                          context.findAncestorStateOfType<_SearchScreenState>()
                              ?._fillQuery(s.name);
                        },
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AllStoreTile extends ConsumerWidget {
  const _AllStoreTile({required this.store, required this.onTap});
  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedColor = store.coverColor != null
        ? Color(store.coverColor!)
        : AppColors.primary;
    final logoUrl = store.imageUrl;
    final productsAsync = ref.watch(storeProductsProvider(store.id));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Üst satır: logo + isim + puan ---
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? CachedNetworkImage(imageUrl: 
                            logoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _logoFallback(seedColor),
                          )
                        : _logoFallback(seedColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${store.type.label} • ${store.deliveryTimeLabel}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 13),
                        const SizedBox(width: 3),
                        Text(store.rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),

              // --- Ürün önizleme ---
              productsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (products) {
                  if (products.isEmpty) return const SizedBox.shrink();
                  final preview = products.take(4).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: preview.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              _ProductPreviewCard(product: preview[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoFallback(Color seedColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: seedColor.withValues(alpha: 0.15),
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(Icons.storefront_rounded, color: seedColor, size: 36),
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün görseli
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? CachedNetworkImage(imageUrl: 
                    product.imageUrl!,
                    width: 130,
                    height: 85,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgFallback(),
                  )
                : _imgFallback(),
          ),
          // İsim + fiyat
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.labelSmall.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₺${product.price.toStringAsFixed(0)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      width: 130,
      height: 85,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.fastfood_rounded,
          color: AppColors.primary, size: 28),
    );
  }
}

// ============================================================
//  Arama Sonuçları
// ============================================================

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.query,
    required this.typeFilter,
    required this.onStoreTap,
  });
  final String query;
  final StoreType? typeFilter;
  final void Function(Store) onStoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final productsAsync = ref.watch(popularProductsProvider);

    return storesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        title: 'Sonuçlar yüklenemedi',
        message: e.toString(),
        icon: Icons.error_outline_rounded,
      ),
      data: (allStores) {
        final q = query.toLowerCase();

        // Mağaza filtresi
        final stores = allStores.where((s) {
          final matchType = typeFilter == null || s.type == typeFilter;
          final matchQuery = s.name.toLowerCase().contains(q) ||
              s.tags.any((t) => t.toLowerCase().contains(q));
          return matchType && matchQuery;
        }).toList();

        // Ürün filtresi (popularProducts'tan)
        List<Product> products = [];
        productsAsync.whenData((all) {
          products = all.where((p) {
            final matchQuery = p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q);
            final storeMatch = typeFilter == null ||
                stores.any((s) => s.id == p.storeId);
            return matchQuery && storeMatch;
          }).toList();
        });

        final totalCount = stores.length + products.length;

        if (totalCount == 0) {
          return EmptyState(
            title: '"$query" için sonuç bulunamadı',
            message: 'Farklı bir kelime deneyin veya filtreyi kaldırın.',
            icon: Icons.search_off_rounded,
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
          children: [
            Text('$totalCount sonuç bulundu',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),

            // Mağazalar
            if (stores.isNotEmpty) ...[
              Text('Mağazalar', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...stores.map((s) => _StoreResultTile(
                    store: s,
                    onTap: () => onStoreTap(s),
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Ürünler
            if (products.isNotEmpty) ...[
              Text('Ürünler', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...products.map((p) {
                final store = allStores.firstWhere(
                  (s) => s.id == p.storeId,
                  orElse: () => Store(
                    id: p.storeId,
                    name: 'Mağaza',
                    type: StoreType.restaurant,
                    rating: 0,
                    reviewCount: 0,
                    deliveryTimeMinutes: 0,
                    deliveryFee: 0,
                    minOrder: 0,
                    tags: [],
                  ),
                );
                return _ProductResultTile(
                  product: p,
                  storeName: store.name,
                  onTap: () => onStoreTap(store),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

// ============================================================
//  Tile widget'ları
// ============================================================

class _StoreResultTile extends StatelessWidget {
  const _StoreResultTile({required this.store, required this.onTap});
  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final seedColor = store.coverColor != null
        ? Color(store.coverColor!)
        : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Logo placeholder
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: seedColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(Icons.storefront_rounded,
                    color: seedColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${store.type.label} • ${store.deliveryTimeLabel}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 15),
                  const SizedBox(width: 2),
                  Text(store.rating.toStringAsFixed(1),
                      style: AppTypography.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({
    required this.product,
    required this.storeName,
    required this.onTap,
  });
  final Product product;
  final String storeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.fastfood_rounded,
                    color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(storeName,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text(
                '₺${product.price.toStringAsFixed(0)}',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Yardımcı widget
// ============================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}


