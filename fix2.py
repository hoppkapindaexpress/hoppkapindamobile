path = 'C:/hopp_kapinda/lib/features/courier/courier_orders_screen.dart'
content = open(path, encoding='utf-8').read()

old = """        'pending' => AppColors.warning,
        'confirmed' => AppColors.info,
        'preparing' => AppColors.secondary,
        'on_the_way' => AppColors.primary,
        'delivered' => AppColors.success,"""
new = """        'pending' => AppColors.warning,
        'confirmed' => AppColors.info,
        'preparing' => AppColors.secondary,
        'ready' => AppColors.success,
        'on_the_way' => AppColors.primary,
        'delivered' => AppColors.success,"""
content = content.replace(old, new)

old2 = """      'pending' => ('Onay Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'on_the_way' => ('Yolda', AppColors.primary),
      'delivered' => ('Teslim Edildi', AppColors.success),"""
new2 = """      'pending' => ('Onay Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'ready' => ('Kurye Bekleniyor 📦', AppColors.success),
      'on_the_way' => ('Yolda', AppColors.primary),
      'delivered' => ('Teslim Edildi', AppColors.success),"""
content = content.replace(old2, new2)

open(path, 'w', encoding='utf-8').write(content)
print('courier_orders_screen.dart OK')
