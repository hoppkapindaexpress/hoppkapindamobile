path = r'C:\hopp_kapinda\lib\services\notification_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if '.resolvePlatformSpecificImplementation' in line and '<' not in line:
        lines[i] = line.rstrip('\n') + '<\n'
        print(f'Satir {i+1} duzeltildi: {repr(lines[i])}')
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('TAMAM')
