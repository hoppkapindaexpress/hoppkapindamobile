path = 'C:/hopp_kapinda/lib/features/orders/order_service.dart'
content = open(path, encoding='utf-8').read()

old = "'on_the_way' => 'Yolda',\n        'delivered' => 'Teslim edildi',\n        'cancelled' => '\u0130ptal edildi',"
new = "'ready' => 'Kurye bekleniyor',\n        'on_the_way' => 'Yolda',\n        'delivered' => 'Teslim edildi',\n        'cancelled' => '\u0130ptal edildi',"

if old in content:
    content = content.replace(old, new)
    open(path, 'w', encoding='utf-8').write(content)
    print('OK')
else:
    print('NOT FOUND')
