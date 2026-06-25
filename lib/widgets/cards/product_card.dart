import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../features/product_favorites/product_favorites_provider.dart';
import '../../features/cart/cart_provider.dart';
import '../../features/restaurant/product_options_sheet.dart';
import '../../models/store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ürün kartı — grid veya yatay listede kullanılır.
class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    this.oldPrice,
    this.imageUrl,
    this.storeName,
    this.rating = 0,
    this.reviewCount = 0,
    this.onTap,
    this.onAdd,
    this.product,
  });

  final String productId;
  final String name;
  final double price;
  final double? oldPrice;
  final String? imageUrl;
  final String? storeName;
  final double rating;
  final int reviewCount;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  /// Ürün seçenekleri için tam Product nesnesi.
  /// Verilirse options kontrolü kart içinde yapılır,
  /// onAdd callback'i yoksayılır.
  final Product? product;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _handleAdd() {
    _bounce.forward(from: 0);

    final p = widget.product;

    // Product nesnesi verilmişse options kontrolü burada yapılır
    if (p != null) {
      if (p.options.isEmpty) {
        ref.read(cartProvider.notifier).add(p);
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProductOptionsSheet(product: p),
        );
      }
      return;
    }

    // Geriye dönük uyumluluk: product verilmemişse eski onAdd callback
    widget.onAdd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = ref.watch(productFavoritesProvider).contains(widget.productId);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Görsel + rozetler ────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Görsel
                    widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => _placeholder(),
                          )
                        : _placeholder(),

                    // Puan rozeti (sol alt) — sadece rating > 0 ise göster
                    if (widget.rating > 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.pillAll,
                            boxShadow: AppShadows.soft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.warning, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                widget.reviewCount > 0
                                    ? '${widget.rating.toStringAsFixed(1)} (${_countLabel(widget.reviewCount)})'
                                    : widget.rating.toStringAsFixed(1),
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Favori kalbi (sağ üst)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(productFavoritesProvider.notifier)
                            .toggle(widget.productId),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.soft,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
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
            ),

            // ── Metin + fiyat + buton ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall),
                  if (widget.storeName != null) ...[
                    const SizedBox(height: 2),
                    Text(widget.storeName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _priceRow(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _addButton(),
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

  /// 70+ / 1.2B gibi kısaltılmış yorum sayısı.
  String _countLabel(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}B';
    return '$count+';
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVariant,
            AppColors.surfaceVariant.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Icon(Icons.fastfood_rounded,
          color: AppColors.softGray, size: 40),
    );
  }

  Widget _priceRow() {
    return Text('₺${widget.price.toStringAsFixed(2)}',
        maxLines: 1,
        style: AppTypography.price.copyWith(color: AppColors.primary));
  }

  Widget _addButton() {
    final scale = Tween<double>(begin: 1, end: 1.25)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_bounce);

    return GestureDetector(
      onTap: _handleAdd,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: AppRadius.smAll,
            boxShadow: AppShadows.accentGlow,
          ),
          child: const Icon(Icons.add_rounded,
              color: AppColors.textOnPrimary, size: 22),
        ),
      ),
    );
  }
}




