import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';

/// Haritadan adres seçme ekranı.
///
/// Kullanım:
/// ```dart
/// final result = await Navigator.push<_LocationResult>(
///   context,
///   MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
/// );
/// if (result != null) {
///   // result.address, result.district, result.city
/// }
/// ```
///
/// Akış:
///  1. Ekran açılır → cihaz konumu istenir.
///  2. İzin varsa harita o konuma gider; yoksa İstanbul merkezinden başlar.
///  3. Kullanıcı pini sürükleyerek doğru yere bırakır.
///  4. "Bu Konumu Kullan" → reverse geocode → caller'a [LocationResult] döner.

class LocationResult {
  const LocationResult({
    required this.address,
    required this.district,
    required this.city,
    required this.latLng,
  });
  final String address;
  final String district;
  final String city;
  final LatLng latLng;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultPos = LatLng(36.2637, 36.0687); // Reyhanlı, Hatay

  final Completer<GoogleMapController> _ctrl = Completer();
  LatLng _pinPos = _defaultPos;
  bool _loadingLocation = true;
  bool _geocoding = false;
  bool _satellite = false;
  bool _locationSelected = false;
  String? _previewAddress;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  // ── Konum izni + GPS ─────────────────────────────────────────
  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLoading(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setLoading(false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setLoading(false);
        _showPermissionDialog();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pinPos = latLng;
        _loadingLocation = false;
        _locationSelected = true;
      });

      final mapCtrl = await _ctrl.future;
      mapCtrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _reverseGeocode(latLng);
    } catch (_) {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) => setState(() => _loadingLocation = v);

  // ── Reverse geocode ───────────────────────────────────────────
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _geocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.thoroughfare,
        ].where((e) => e != null && e.isNotEmpty).toList();

        setState(() {
          _previewAddress = parts.isNotEmpty
              ? parts.join(', ')
              : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _previewAddress =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  // ── "Bu Konumu Kullan" ─────────────────────────────────────────
  Future<void> _confirmLocation() async {
    setState(() => _geocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        _pinPos.latitude,
        _pinPos.longitude,
      );

      String address = _previewAddress ?? '';
      String district = '';
      String city = '';

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final streetParts = [
          p.street,
          p.subLocality,
          p.thoroughfare,
        ].where((e) => e != null && e.isNotEmpty).toList();
        address = streetParts.isNotEmpty ? streetParts.join(', ') : address;
        district = p.subAdministrativeArea ?? p.locality ?? '';
        city = p.administrativeArea ?? '';
      }

      if (!mounted) return;
      Navigator.of(context).pop(LocationResult(
        address: address,
        district: district,
        city: city,
        latLng: _pinPos,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adres alınamadı, tekrar dene')),
        );
        setState(() => _geocoding = false);
      }
    }
  }

  // ── İzin kalıcı reddedilmişse ayarlar diyalogu ───────────────
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: const Text(
          'Konumunuzu kullanabilmek için ayarlardan konum iznini açmanız gerekiyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Harita ─────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (ctrl) => _ctrl.complete(ctrl),
            initialCameraPosition: CameraPosition(
              target: _pinPos,
              zoom: 14,
            ),
            mapType: _satellite ? MapType.satellite : MapType.normal,
            markers: _locationSelected
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _pinPos,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (latLng) {
              setState(() {
                _pinPos = latLng;
                _previewAddress = null;
                _locationSelected = true;
              });
              _reverseGeocode(latLng);
            },
          ),

          // ── Yükleniyor göstergesi (GPS alınırken) ─────────────
          if (_loadingLocation)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text('Konumunuz alınıyor...'),
                    ],
                  ),
                ),
              ),
            ),

          // ── "Konumuma Git" butonu ──────────────────────────────
          Positioned(
            bottom: 160,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_type',
                  backgroundColor: _satellite ? AppColors.primary : Colors.white,
                  foregroundColor: _satellite ? Colors.white : AppColors.primary,
                  onPressed: () => setState(() => _satellite = !_satellite),
                  child: const Icon(Icons.layers_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: _fetchCurrentLocation,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // ── Alt panel: adres önizleme + onayla ────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sürükleme tutacağı
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Seçilen Konum',
                          style: AppTypography.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_geocoding)
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text('Adres aranıyor...',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.softGray)),
                      ],
                    )
                  else
                    Text(
                      _previewAddress ?? 'Haritaya tıklayarak konum seç',
                      style: AppTypography.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: AppSpacing.md),

                  AppButton(
                    label: 'Bu Konumu Kullan',
                    icon: Icons.check_rounded,
                    loading: _geocoding,
                    onPressed: _geocoding ? null : _confirmLocation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
