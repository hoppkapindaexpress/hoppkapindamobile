path = 'C:/hopp_kapinda/lib/features/orders/order_service.dart'
content = open(path, encoding='utf-8').read()

old = """        'pending' => 0,
        'confirmed' => 1,
        'preparing' => 2,
        'on_the_way' => 3,
        'delivered' => 4,
        'cancelled' => -1,"""
new = """        'pending' => 0,
        'confirmed' => 1,
        'preparing' => 2,
        'ready' => 3,
        'on_the_way' => 4,
        'delivered' => 5,
        'cancelled' => -1,"""
content = content.replace(old, new)

old2 = """        'pending' => 'Onay bekliyor',
        'confirmed' => 'Onaylandı',
        'preparing' => 'Hazırlanıyor',
        'on_the_way' => 'Yolda',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'ptal edildi',"""
new2 = """        'pending' => 'Onay bekliyor',
        'confirmed' => 'Onaylandı',
        'preparing' => 'Hazırlanıyor',
        'ready' => 'Kurye bekleniyor',
        'on_the_way' => 'Yolda',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'ptal edildi',"""
content = content.replace(old2, new2)

open(path, 'w', encoding='utf-8').write(content)
print('order_service.dart OK')
