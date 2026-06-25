import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/widgets.dart';
import 'address_provider.dart';
import 'location_picker_screen.dart';

/// Adres Yönetimi ekranı.
///
/// Yeni adres eklemek veya düzenlemek için her zaman konum seçici açılır.
/// Konum onaylandıktan sonra sadece başlık / tip / kat / daire / not sorulan
/// minimal bir sheet açılır; adres / ilçe / şehir konumdan otomatik gelir.
class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Adreslerim'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppColors.textDark,
      ),
      body: addresses.isEmpty
          ? _emptyState(context, ref)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                ...addresses.map((a) => _AddressTile(
                      address: a,
                      onEdit: () => _pickAndSave(context, ref, existing: a),
                      onDelete: () => _confirmDelete(context, ref, a),
                      onSetDefault: () =>
                          ref.read(addressProvider.notifier).setDefault(a.id),
                    )),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'location_pick',
        onPressed: () => _pickAndSave(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.my_location_rounded),
        label: const Text('Yeni Adres Ekle'),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: 'Henüz adres eklemediniz',
      message: 'Sipariş verebilmek için en az bir adres eklemeniz gerekiyor.',
      icon: Icons.location_off_rounded,
      action: AppButton(
        label: 'Konumdan Adres Ekle',
        expanded: false,
        icon: Icons.my_location_rounded,
        onPressed: () => _pickAndSave(context, ref),
      ),
    );
  }

  /// 1. Harita ekranını açar.
  /// 2. Konum onaylanınca detay sheet'ini açar (başlık/tip/kat/daire/not).
  /// 3. Detaylar kaydedilince adresi provider'a yazar.
  Future<void> _pickAndSave(
    BuildContext context,
    WidgetRef ref, {
    UserAddress? existing,
  }) async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DetailsSheet(
          location: result,
          existing: existing,
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, UserAddress address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adresi sil'),
        content: Text('"${address.title}" adresini silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(addressProvider.notifier).remove(address.id);
              Navigator.pop(ctx);
              AppToast.show(context, 'Adres silindi');
            },
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Adres Tile
// ============================================================

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });
  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(address.type.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(address.title, style: AppTypography.titleMedium),
                          if (address.isDefault) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Varsayılan',
                                  style: AppTypography.labelSmall
                                      .copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(address.shortAddress,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                    if (v == 'default') onSetDefault();
                  },
                  itemBuilder: (_) => [
                    if (!address.isDefault)
                      const PopupMenuItem(
                          value: 'default', child: Text('Varsayılan Yap')),
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil',
                            style: TextStyle(color: AppColors.error))),
                  ],
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.softGray, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              address.fullAddress,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (address.floor != null || address.doorNo != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (address.floor != null) 'Kat: ${address.floor}',
                  if (address.doorNo != null) 'Daire: ${address.doorNo}',
                ].join('  •  '),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Detay Sheet — konum seçildikten sonra açılır
//  Sadece başlık / tip / kat / daire / not / varsayılan sorar.
//  Adres, ilçe, şehir konumdan otomatik gelir; gösterilir ama düzenlenemez.
// ============================================================

class _DetailsSheet extends ConsumerStatefulWidget {
  const _DetailsSheet({required this.location, this.existing});
  final LocationResult location;
  final UserAddress? existing;

  @override
  ConsumerState<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends ConsumerState<_DetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _doorCtrl;
  late final TextEditingController _noteCtrl;
  late AddressType _type;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _type = a?.type ?? AddressType.home;
    _isDefault = a?.isDefault ?? false;
    _titleCtrl = TextEditingController(text: a?.title ?? _type.label);
    _floorCtrl = TextEditingController(text: a?.floor ?? '');
    _doorCtrl = TextEditingController(text: a?.doorNo ?? '');
    _noteCtrl = TextEditingController(text: a?.note ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _floorCtrl.dispose();
    _doorCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final loc = widget.location;
    final address = UserAddress(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      title: _titleCtrl.text.trim(),
      fullAddress: loc.address,
      district: loc.district,
      city: loc.city,
      floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
      doorNo: _doorCtrl.text.trim().isEmpty ? null : _doorCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      lat: loc.latLng.latitude,
      lng: loc.latLng.longitude,
      isDefault: _isDefault,
    );

    if (_isEdit) {
      await ref.read(addressProvider.notifier).update(address);
    } else {
      await ref.read(addressProvider.notifier).add(address);
    }

    if (mounted) {
      Navigator.pop(context);
      AppToast.show(context, _isEdit ? 'Adres güncellendi' : 'Adres eklendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final safePad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Adresi Düzenle' : 'Yeni Adres',
          style: AppTypography.titleLarge,
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        // Klavye açılınca içerik kaydırılabilsin (taşma olmasın),
        // ama yer varken buton + toggle yine de en alta yapışsın.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                safePad + AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      AppSpacing.md -
                      safePad -
                      AppSpacing.md,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // ── Seçilen konum özeti (salt okunur) ──────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.address,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (loc.district.isNotEmpty || loc.city.isNotEmpty)
                            Text('${loc.district}, ${loc.city}',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Adres tipi ──────────────────────────────────────
              Text('Adres Türü',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: AddressType.values.map((t) {
                  final sel = _type == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          if (_titleCtrl.text.isEmpty ||
                              AddressType.values
                                  .any((v) => v.label == _titleCtrl.text)) {
                            _titleCtrl.text = t.label;
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : Theme.of(context).cardColor,
                            borderRadius: AppRadius.smAll,
                            border: Border.all(
                              color:
                                  sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(t.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(t.label,
                                  style: AppTypography.labelSmall.copyWith(
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Başlık ──────────────────────────────────────────
              AppTextField(
                controller: _titleCtrl,
                label: 'Adres Başlığı',
                hint: 'Örn: Ev, İş, Annem',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Kat / Daire ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _floorCtrl,
                      label: 'Kat (isteğe bağlı)',
                      hint: '3',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _doorCtrl,
                      label: 'Daire (isteğe bağlı)',
                      hint: '7',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Kurye notu ──────────────────────────────────────
              AppTextField(
                controller: _noteCtrl,
                label: 'Kurye Notu (isteğe bağlı)',
                hint: 'Örn: Kapı kodu 1234, zil çalışmıyor',
                maxLines: 2,
              ),

              // ── Boşluğu doldur, buton + toggle alta yapışsın ───
              const Spacer(),

              // ── Varsayılan toggle ───────────────────────────────
              SwitchListTile(
                value: _isDefault,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text('Varsayılan adres olarak kaydet',
                    style: AppTypography.titleMedium),
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Kaydet ──────────────────────────────────────────
              AppButton(
                label: _isEdit ? 'Güncelle' : 'Adresi Kaydet',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
