import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Résultat de la position avec coordonnées et adresse (si disponible).
class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

/// Service de géolocalisation : permissions, position GPS, géocodage inverse.
class LocationService {
  /// Vérifie et demande la permission de localisation.
  /// Retourne true si accordée (ou déjà accordée).
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Vérifie si le service de localisation est activé.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Récupère la position actuelle et optionnellement l'adresse (géocodage inverse).
  /// Retourne null en cas d'erreur ou de permission refusée.
  static Future<LocationResult?> getCurrentPosition({bool fetchAddress = true}) async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) return null;

    final granted = await requestPermission();
    if (!granted) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String? address;
      if (fetchAddress) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              if (p.street != null && p.street!.isNotEmpty) p.street,
              if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality,
              if (p.country != null && p.country!.isNotEmpty) p.country,
            ].whereType<String>().toList();
            address = parts.isNotEmpty ? parts.join(', ') : null;
          }
        } catch (_) {
          // Géocodage optionnel : on garde quand même les coordonnées
        }
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      return null;
    }
  }
}
