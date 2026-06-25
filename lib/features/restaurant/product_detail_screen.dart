import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/store.dart';
import '../../services/providers.dart';
import '../../widgets/widgets.dart';
import '../cart/cart_provider.dart';
import 'product_options_sheet.dart';
import 'product_options_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(productProvider(widget.id)));
  }

  Future<void> _refresh() async {
    ref.invalidate(productProvider(widget.id));
    await ref.read(productProvider(widget.id).future);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.id));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Ürün yüklenemedi',
          icon: Icons.error_outline_rounded,
          action: AppButton(
            label: 'Geri dön',
            expanded: false,
            onPressed: () => context.pop(),
          ),
        ),
        data: (product) => _content(product),
      ),
    );
  }

  Widget _content(Product product) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _heroImage(product),
                ),
              ),
              SliverToBoxAdapter(child: _details(product)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        Align(alignment: Alignment.bottomCenter, child: _addBar(product)),
      ],
    );
  }

  Widget _heroImage(Product product) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    if (hasImage) {
      return CachedNetworkImage(imageUrl: 
        product.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (_, __, ___) => _heroFallback(),
      );
    }
    return _heroFallback();
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Colors.white60, size: 96),
      ),
    );
  }

  Widget _details(Product product) {
    return Container(
      transform: Matrix4.translationValues(0, -20, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product.name, style: AppTypography.displayMedium)),
              if (product.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text('İNDİRİM',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₺${product.price.toStringAsFixed(2)}',
                  style: AppTypography.headlineMedium.copyWith(color: AppColors.primary)),
              if (product.oldPrice != null) ...[
                const SizedBox(width: 8),
                Text('₺${product.oldPrice!.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.softGray,
                    )),
              ],
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Açıklama', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(product.description, style: AppTypography.bodyLarge),
          ],
          if (product.ingredients.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('İçindekiler', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.ingredients
                  .map((ing) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(ing, style: AppTypography.labelMedium),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addBar(Product product) {
    final lineTotal = product.price * _quantity;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.md, AppSpacing.screenPadding, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                children: [
                  _qtyButton(Icons.remove_rounded,
                      () => setState(() => _quantity = (_quantity - 1).clamp(1, 99))),
                  SizedBox(
                    width: 32,
                    child: Text('$_quantity',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge),
                  ),
                  _qtyButton(Icons.add_rounded,
                      () => setState(() => _quantity = (_quantity + 1).clamp(1, 99))),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Sepete Ekle · ₺${lineTotal.toStringAsFixed(2)}',
                variant: AppButtonVariant.gradient,
                onPressed: () {
                  if (product.options.isEmpty) {
                    ref.read(cartProvider.notifier).add(product, quantity: _quantity);
                    AppToast.success(context, '$_quantity x ${product.name} sepete eklendi');
                    context.pop();
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProductOptionsSheet(product: product),
                    ).then((_) {
                      if (context.mounted) context.pop();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: AppColors.textDark),
      ),
    );
  }
}


