path = 'C:/hopp_kapinda/lib/features/courier/courier_delivery_screen.dart'
content = open(path, encoding='utf-8').read()

old = """                child: isDelivered
                    ? Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Teslim Edildi',
                                style: AppTypography.titleMedium
                                    .copyWith(color: AppColors.success)),
                          ],
                        ),
                      )
                    : isOnTheWay
                        ? ElevatedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _completeDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.mdAll),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.check_circle_outline_rounded),
                            label: Text(
                              _actionLoading
                                  ? 'şleniyor...'
                                  : '✅ Teslim Ettim',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _startDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.mdAll),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.delivery_dining_rounded),
                            label: Text(
                              _actionLoading
                                  ? 'şleniyor...'
                                  : '🛵 Yola Çık',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),"""
new = """                child: isDelivered
                    ? Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Teslim Edildi',
                                style: AppTypography.titleMedium
                                    .copyWith(color: AppColors.success)),
                          ],
                        ),
                      )
                    : isOnTheWay
                        ? ElevatedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _completeDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.mdAll),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.check_circle_outline_rounded),
                            label: Text(
                              _actionLoading
                                  ? 'şleniyor...'
                                  : '✅ Teslim Ettim',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                          )
                        : isReady
                            ? ElevatedButton.icon(
                                onPressed: _actionLoading
                                    ? null
                                    : () => _startDelivery(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.mdAll),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                ),
                                icon: _actionLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(
                                        Icons.delivery_dining_rounded),
                                label: Text(
                                  _actionLoading
                                      ? 'şleniyor...'
                                      : '🛵 Yola Çık',
                                  style: AppTypography.titleMedium
                                      .copyWith(color: Colors.white),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.mdAll,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.hourglass_top_rounded,
                                        color: AppColors.warning),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text('Mağaza hazırlanıyor...',
                                        style: AppTypography.titleMedium
                                            .copyWith(color: AppColors.warning)),
                                  ],
                                ),
                              ),"""
content = content.replace(old, new)
open(path, 'w', encoding='utf-8').write(content)
print('courier_delivery_screen.dart buton OK')
