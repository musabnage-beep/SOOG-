import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';

class MapPickerArgs {
  const MapPickerArgs({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Result returned by [MapPickerScreen] when the user confirms a location.
class MapPickerResult {
  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.district = '',
    this.street = '',
  });

  final double latitude;
  final double longitude;
  final String city;
  final String district;
  final String street;
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final MapPickerArgs? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _picked;
  bool _resolving = false;
  String _label = 'حرّك الخريطة لتحديد الموقع';

  @override
  void initState() {
    super.initState();
    _picked = LatLng(
      widget.initial?.latitude ?? 24.7136,
      widget.initial?.longitude ?? 46.6753,
    );
    _reverseGeocode();
    _tryMyLocation();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _tryMyLocation() async {
    if (widget.initial != null) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = target);
      _controller?.animateCamera(CameraUpdate.newLatLng(target));
      _reverseGeocode();
    } catch (_) {
      // ignore, keep default
    }
  }

  Future<void> _reverseGeocode() async {
    setState(() => _resolving = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(_picked.latitude, _picked.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality]
            .where((e) => e != null && e.isNotEmpty)
            .join('، ');
        setState(() => _label = parts.isEmpty ? 'موقع محدّد' : parts);
      }
    } catch (_) {
      setState(() => _label = 'موقع محدّد');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _confirm() async {
    String city = '', district = '', street = '';
    try {
      final placemarks =
          await placemarkFromCoordinates(_picked.latitude, _picked.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = p.locality ?? p.administrativeArea ?? '';
        district = p.subLocality ?? '';
        street = p.street ?? '';
      }
    } catch (_) {
      // proceed with coordinates only
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      MapPickerResult(
        latitude: _picked.latitude,
        longitude: _picked.longitude,
        city: city,
        district: district,
        street: street,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديد الموقع')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _picked, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _controller = c,
            onCameraMove: (pos) => _picked = pos.target,
            onCameraIdle: _reverseGeocode,
          ),
          // Center pin.
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(Icons.location_pin, size: 48, color: AppColors.danger),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resolving
                            ? const Text('جارٍ تحديد العنوان...',
                                style: TextStyle(color: AppColors.muted))
                            : Text(_label,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _confirm,
                    child: const Text('تأكيد الموقع'),
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
