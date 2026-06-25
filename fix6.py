path = 'C:/hopp_kapinda/lib/features/orders/order_service.dart'
content = open(path, encoding='utf-8').read()

old = """        'pending' => 'Onay bekliyor',
        'confirmed' => 'Onaylandı',
        'preparing' => 'Hazırlanıyor',
        'on_the_way' => 'Yolda',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'ptal edildi',"""
new = """        'pending' => 'Onay bekliyor',
        'confirmed' => 'Onaylandı',
        'preparing' => 'Hazırlanıyor',
        'ready' => 'Kurye bekleniyor',
        'on_the_way' => 'Yolda',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'ptal edildi',"""

if old in content:
    content = content.replace(old, new)
    open(path, 'w', encoding='utf-8').write(content)
    print('OK - replaced')
else:
    print('NOT FOUND - printing context:')
    idx = content.find("'pending' => 'Onay bekliyor'")
    print(repr(content[idx:idx+300]))
