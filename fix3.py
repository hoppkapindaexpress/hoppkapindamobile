path = 'C:/hopp_kapinda/lib/features/courier/courier_delivery_screen.dart'
content = open(path, encoding='utf-8').read()

old = """      'pending' => ('Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'on_the_way' => ('Yolda 🛵', AppColors.primary),
      'delivered' => ('Teslim ✅', AppColors.success),"""
new = """      'pending' => ('Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'ready' => ('Kurye Bekleniyor 📦', AppColors.success),
      'on_the_way' => ('Yolda 🛵', AppColors.primary),
      'delivered' => ('Teslim ✅', AppColors.success),"""
content = content.replace(old, new)

old2 = "    final isOnTheWay = order.status == 'on_the_way';\n    final isDelivered = order.status == 'delivered';"
new2 = "    final isReady = order.status == 'ready';\n    final isOnTheWay = order.status == 'on_the_way';\n    final isDelivered = order.status == 'delivered';"
content = content.replace(old2, new2)

open(path, 'w', encoding='utf-8').write(content)
print('courier_delivery_screen.dart OK')
