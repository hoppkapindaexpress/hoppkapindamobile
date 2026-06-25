import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/api_store_repository.dart';

// ============================================================
//  Model
// ============================================================

enum AddressType { home, work, other }

extension AddressTypeX on AddressType {
  String get label => switch (this) {
        AddressType.home => 'Ev',
        AddressType.work => 'İş',
        AddressType.other => 'Diğer',
      };

  String get icon => switch (this) {
        AddressType.home => '🏠',
        AddressType.work => '🏢',
        AddressType.other => '📍',
      };
}

/// Backend label (Ev/İş/Diğer) -> AddressType
AddressType _typeFromLabel(String? label) {
  switch (label) {
    case 'İş':
      return AddressType.work;
    case 'Diğer':
      return AddressType.other;
    default:
      return AddressType.home;
  }
}

/// lat/lng backend'den String olarak gelebiliyor ("36.255...") — güvenli parse.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// is_default backend'den bool ya da int (0/1) gelebiliyor.
bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

/// Kullanıcı adres modeli.
class UserAddress {
  const UserAddress({
    required this.id,
    required this.type,
    required this.title,
    required this.fullAddress,
    required this.district,
    required this.city,
    this.floor,
    this.doorNo,
    this.note,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  final String id;
  final AddressType type;
  final String title;
  final String fullAddress;
  final String district;
  final String city;
  final String? floor;
  final String? doorNo;
  final String? note;
  final double? lat;
  final double? lng;
  final bool isDefault;

  String get shortAddress =>
      district.isNotEmpty || city.isNotEmpty ? '$district, $city' : fullAddress;

  UserAddress copyWith({
    AddressType? type,
    String? title,
    String? fullAddress,
    String? district,
    String? city,
    String? floor,
    String? doorNo,
    String? note,
    double? lat,
    double? lng,
    bool? isDefault,
  }) =>
      UserAddress(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        fullAddress: fullAddress ?? this.fullAddress,
        district: district ?? this.district,
        city: city ?? this.city,
        floor: floor ?? this.floor,
        doorNo: doorNo ?? this.doorNo,
        note: note ?? this.note,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isDefault: isDefault ?? this.isDefault,
      );

  /// Backend'e gönderilecek gövde (addresses tablosu alanları).
  Map<String, dynamic> toApi() => {
        'label': title.isNotEmpty ? title : type.label,
        'full_address': fullAddress,
        'building': doorNo,
        'floor': floor,
        'directions': note,
        'lat': lat,
        'lng': lng,
        'is_default': isDefault,
      };

  /// Backend'den gelen kayıt (addresses tablosu) -> UserAddress.
  /// FIX: lat/lng String olarak geliyor, is_default bool/int farklı olabiliyor.
  factory UserAddress.fromApi(Map<String, dynamic> j) {
    final full = (j['full_address'] as String?) ?? '';

    // full_address → district / city ayrıştırma.
    // Örnek: "Kurtuluş, Kurtuluş, Hamit Öcal Caddesi, Reyhanlı, Hatay"
    //   → city = "Hatay", district = "Reyhanlı"
    // Örnek: "Bahçelievler, Bahçelievler, 316. Sokak"
    //   → city = "316. Sokak" olmaz; en az 4 parça varsa son iki al,
    //     yoksa full_address'i olduğu gibi göster.
    final parts = full
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Şehir ve ilçeyi yalnızca yeterli parça varsa al (≥ 4 parça = adres yeterince detaylı).
    final city = parts.length >= 4 ? parts.last : '';
    final district = parts.length >= 4 ? parts[parts.length - 2] : '';

    return UserAddress(
      id: j['id'].toString(),
      type: _typeFromLabel(j['label'] as String?),
      title: (j['label'] as String?) ?? 'Adres',
      fullAddress: full,
      district: district,
      city: city,
      floor: j['floor']?.toString(),          // int gelse de String'e çevir
      doorNo: j['building']?.toString(),
      note: j['directions']?.toString(),
      lat: _toDouble(j['lat']),               // "36.255..." String → double
      lng: _toDouble(j['lng']),
      isDefault: _toBool(j['is_default']),    // bool | int | String → bool
    );
  }
}

// ============================================================
//  Notifier — API tabanlı (adresler sunucuda kalıcı)
// ============================================================

final addressProvider =
    StateNotifierProvider<AddressNotifier, List<UserAddress>>(
        (ref) => AddressNotifier()..load());

class AddressNotifier extends StateNotifier<List<UserAddress>> {
  AddressNotifier() : super([]);

  /// Sunucudan adresleri çek.
  Future<void> load() async {
    try {
      final dio = await DioFactory.create();
      final res = await dio.get('/addresses');
      final raw = (res.data is Map) ? res.data['data'] : res.data;
      if (raw is List) {
        state = raw
            .map((e) => UserAddress.fromApi(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      // Hataları logla ama çökme.
      // ignore: avoid_print
      print('ADDRESS LOAD ERROR: $e\n$st');
    }
  }

  Future<void> add(UserAddress address) async {
    try {
      final dio = await DioFactory.create();
      final body = address.toApi();
      if (state.isEmpty) body['is_default'] = true;
      await dio.post('/addresses', data: body);
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('ADDRESS ADD ERROR: $e');
    }
  }

  Future<void> update(UserAddress address) async {
    try {
      final dio = await DioFactory.create();
      await dio.put('/addresses/${address.id}', data: address.toApi());
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('ADDRESS UPDATE ERROR: $e');
    }
  }

  Future<void> remove(String id) async {
    try {
      final dio = await DioFactory.create();
      await dio.delete('/addresses/$id');
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('ADDRESS REMOVE ERROR: $e');
    }
  }

  Future<void> setDefault(String id) async {
    try {
      final dio = await DioFactory.create();
      final addr = state.firstWhere((a) => a.id == id);
      await dio.put('/addresses/$id',
          data: addr.copyWith(isDefault: true).toApi());
      await load();
    } catch (e) {
      // ignore: avoid_print
      print('ADDRESS SET_DEFAULT ERROR: $e');
    }
  }

  /// Çıkış yapıldığında bellekteki listeyi temizle (sunucudan silmez).
  Future<void> clearAll() async {
    state = [];
  }
}
