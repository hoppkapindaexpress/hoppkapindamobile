import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store.dart';
import '../../features/cart/cart_provider.dart';

class ProductOptionsSheet extends ConsumerStatefulWidget {
  const ProductOptionsSheet({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<ProductOptionsSheet> createState() =>
      _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends ConsumerState<ProductOptionsSheet> {
  // multi grup → { item adı: qty }   (qty 0 = seçili değil)
  final Map<String, Map<String, int>> _multi = {};
  // single grup → seçili item ismi
  final Map<String, String?> _single = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    for (final g in widget.product.options) {
      if (g.isMulti) {
        _multi[g.group] = { for (final it in g.items) it.name: 0 };
      } else {
        _single[g.group] = null;
      }
    }
  }

  bool _groupHasPrice(ProductOptionGroup g) =>
      g.items.any((i) => (i.price) > 0);

  /// Seçimlerden ek fiyat toplamı (qty dahil).
  double get _addonTotal {
    double total = 0;
    for (final g in widget.product.options) {
      if (g.isMulti) {
        final m = _multi[g.group] ?? {};
        for (final item in g.items) {
          final q = m[item.name] ?? 0;
          total += item.price * q;
        }
      } else {
        final selectedName = _single[g.group];
        if (selectedName != null) {
          final item = g.items.cast<ProductOptionItem?>().firstWhere(
                (i) => i?.name == selectedName,
                orElse: () => null,
              );
          total += item?.price ?? 0;
        }
      }
    }
    return total;
  }

  String _buildNote() {
    final parts = <String>[];
    for (final g in widget.product.options) {
      if (g.isMulti) {
        final m = _multi[g.group] ?? {};
        final selected = m.entries
            .where((e) => e.value > 0)
            .map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key)
            .toList();
        if (selected.isNotEmpty) {
          parts.add('${g.group}: ${selected.join(', ')}');
        }
      } else {
        final selected = _single[g.group];
        if (selected != null) parts.add('${g.group}: $selected');
      }
    }
    return parts.join(' | ');
  }

  /// Backend için yapılandırılmış options: [{group, items:[{name, price, qty}]}]
  List<Map<String, dynamic>> _buildStructuredOptions() {
    final list = <Map<String, dynamic>>[];
    for (final g in widget.product.options) {
      if (g.isMulti) {
        final m = _multi[g.group] ?? {};
        final items = <Map<String, dynamic>>[];
        for (final it in g.items) {
          final q = m[it.name] ?? 0;
          if (q <= 0) continue;
          items.add({'name': it.name, 'price': it.price, 'qty': q});
        }
        if (items.isNotEmpty) list.add({'group': g.group, 'items': items});
      } else {
        final sel = _single[g.group];
        if (sel == null) continue;
        final it = g.items.cast<ProductOptionItem?>().firstWhere(
              (i) => i?.name == sel, orElse: () => null);
        list.add({
          'group': g.group,
          'items': [
            {'name': sel, 'price': it?.price ?? 0, 'qty': 1}
          ],
        });
      }
    }
    return list;
  }

  void _addToCart() {
    final structured = _buildStructuredOptions();
    final note = _buildNote();
    final unitPrice = widget.product.price + _addonTotal;

    ref.read(cartProvider.notifier).add(
          widget.product,
          quantity: _quantity,
          note: note.isEmpty ? null : note,
          selectedOptions: { 'structured': structured }, // backend bunu okuyacak
          unitPrice: unitPrice,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unitPrice = product.price + _addonTotal;
    final totalPrice = unitPrice * _quantity;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(imageUrl: product.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey[200])),
                  ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('₺${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF5A00D6), fontWeight: FontWeight.w500)),
                ])),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: product.options.map((group) {
                  final useQty = group.isMulti && _groupHasPrice(group) && group.group.toLowerCase().contains('içecek');
                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(group.group, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      group.isMulti
                          ? (useQty ? 'İstediğin adetlerde seç' : 'Birden fazla seçebilirsiniz')
                          : 'Bir seçenek seçin',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    children: group.items.map((item) {
                      if (group.isMulti) {
                        if (useQty) {
                          final q = _multi[group.group]?[item.name] ?? 0;
                          return _qtyTile(group.group, item, q);
                        } else {
                          final q = _multi[group.group]?[item.name] ?? 0;
                          return CheckboxListTile(
                            value: q > 0,
                            title: _itemLabel(item),
                            dense: true,
                            activeColor: const Color(0xFF5A00D6),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) => setState(() => _multi[group.group]![item.name] = val == true ? 1 : 0),
                          );
                        }
                      } else {
                        final selected = _single[group.group];
                        return RadioListTile<String>(
                          value: item.name,
                          groupValue: selected,
                          title: _itemLabel(item),
                          dense: true,
                          activeColor: const Color(0xFF5A00D6),
                          onChanged: (val) => setState(() => _single[group.group] = val),
                        );
                      }
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      padding: const EdgeInsets.all(6), constraints: const BoxConstraints()),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('$_quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    IconButton(icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                      padding: const EdgeInsets.all(6), constraints: const BoxConstraints()),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A00D6), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Sepete Ekle  •  ₺${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyTile(String groupName, ProductOptionItem item, int q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(child: _itemLabel(item)),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: q > 0 ? const Color(0xFF5A00D6) : Colors.grey[300]!, width: 1.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.remove, size: 16, color: q > 0 ? const Color(0xFF5A00D6) : Colors.grey[400]),
              onPressed: q > 0 ? () => setState(() => _multi[groupName]![item.name] = q - 1) : null,
              padding: const EdgeInsets.all(4), constraints: const BoxConstraints(),
            ),
            SizedBox(
              width: 26,
              child: Text('$q', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: q > 0 ? const Color(0xFF5A00D6) : Colors.grey[400])),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF5A00D6)),
              onPressed: () => setState(() => _multi[groupName]![item.name] = q + 1),
              padding: const EdgeInsets.all(4), constraints: const BoxConstraints(),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _itemLabel(ProductOptionItem item) {
    if (!item.hasPriceAddon) {
      return Text(item.name, style: const TextStyle(fontSize: 14));
    }
    return Row(children: [
      Text(item.name, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('+₺${item.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF7A00))),
      ),
    ]);
  }
}

