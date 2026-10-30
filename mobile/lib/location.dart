import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'l10n.dart';
import 'ui.dart';

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

enum LocationError { disabled, denied, deniedForever, failed }

class LocationException implements Exception {
  final LocationError error;
  const LocationException(this.error);
}

class LocationService {
  /// Current position, asking for permission when needed.
  static Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationError.disabled);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) throw const LocationException(LocationError.denied);
    if (perm == LocationPermission.deniedForever) throw const LocationException(LocationError.deniedForever);
    try {
      // On Android use the platform LocationManager: the Fused provider shows Google's
      // "Location Accuracy" consent dialog and fails if the user declines it.
      final settings = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 15),
            )
          : const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15));
      final p = await Geolocator.getCurrentPosition(locationSettings: settings);
      return GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return GeoPoint(last.latitude, last.longitude);
      throw const LocationException(LocationError.failed);
    }
  }

  /// Human-readable address for coordinates, or null if the platform geocoder fails.
  static Future<String?> addressFor(GeoPoint p, String lang) async {
    try {
      final locale = switch (lang) {
        'en' => const Locale('en', 'US'),
        'ru' => const Locale('ru', 'RU'),
        _ => const Locale('uz', 'UZ'),
      };
      final marks = await Geocoding().placemarkFromCoordinates(p.lat, p.lng, locale: locale);
      if (marks.isEmpty) return null;
      final m = marks.first;
      // `street`/`name` often hold the whole formatted line on Android; prefer thoroughfare + house.
      final street = (m.thoroughfare?.isNotEmpty ?? false)
          ? '${m.thoroughfare} ${m.subThoroughfare ?? ''}'
          : (m.street ?? '').split(',').first;
      final plusCode = RegExp(r'^[0-9A-Z]{4,8}\+[0-9A-Z]{2,3}$');
      final parts = [
        m.subLocality,
        plusCode.hasMatch(street.trim()) ? null : street,
      ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// True when location permission was already granted (no prompt).
  static Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Distance in meters.
  static double distance(GeoPoint a, double lat, double lng) => Geolocator.distanceBetween(a.lat, a.lng, lat, lng);
}

String distanceText(BuildContext context, double meters) => meters < 1000
    ? context.t('m_away', {'d': meters.round()})
    : context.t('km_away', {'d': (meters / 1000).toStringAsFixed(1)});

/// Shows a localized message for a location failure, with a Settings shortcut when useful.
void showLocationError(BuildContext context, Object e) {
  final err = e is LocationException ? e.error : LocationError.failed;
  final msg = switch (err) {
    LocationError.disabled => context.tr('loc_disabled'),
    LocationError.denied || LocationError.deniedForever => context.tr('loc_denied'),
    LocationError.failed => context.tr('unknown_error'),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        action: err == LocationError.failed
            ? null
            : SnackBarAction(
                label: context.tr('open_settings'),
                textColor: C.amberSoft,
                onPressed: () =>
                    err == LocationError.disabled ? Geolocator.openLocationSettings() : Geolocator.openAppSettings(),
              ),
      ),
    );
}
