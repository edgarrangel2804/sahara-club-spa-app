import 'package:flutter/material.dart';

enum ServiceCategory {
  masajes,
  experienciasCorporales,
  faciales,
  tecnologiaFacial,
  moldeoConsciente,
  tecnologiaCorporal,
  experienciasFusionadas,
  saharaHouse,
}

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.masajes:
        return 'Masajes';
      case ServiceCategory.experienciasCorporales:
        return 'Experiencias Corporales';
      case ServiceCategory.faciales:
        return 'Faciales';
      case ServiceCategory.tecnologiaFacial:
        return 'Tecnología Facial';
      case ServiceCategory.moldeoConsciente:
        return 'Moldeo Consciente';
      case ServiceCategory.tecnologiaCorporal:
        return 'Tecnología Corporal';
      case ServiceCategory.experienciasFusionadas:
        return 'Experiencias Fusionadas';
      case ServiceCategory.saharaHouse:
        return 'Sahara House';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.masajes:
        return Icons.self_improvement;
      case ServiceCategory.experienciasCorporales:
        return Icons.spa;
      case ServiceCategory.faciales:
        return Icons.face_retouching_natural;
      case ServiceCategory.tecnologiaFacial:
        return Icons.auto_awesome;
      case ServiceCategory.moldeoConsciente:
        return Icons.accessibility_new;
      case ServiceCategory.tecnologiaCorporal:
        return Icons.electric_bolt;
      case ServiceCategory.experienciasFusionadas:
        return Icons.blur_on;
      case ServiceCategory.saharaHouse:
        return Icons.hotel;
    }
  }
}

class ServiceDuration {
  final int minutes;
  final double price;

  const ServiceDuration({required this.minutes, required this.price});

  String get formattedPrice => '\$${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      )}';

  String get formattedDuration => '$minutes min';
}

class SessionPackage {
  final int sessions;
  final double price;

  const SessionPackage({required this.sessions, required this.price});

  String get formattedPrice => '\$${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      )}';
}

class SpaService {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final ServiceCategory category;
  final List<ServiceDuration> durations;
  final List<SessionPackage> packages;
  final bool priceOnQuote;

  const SpaService({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    this.durations = const [],
    this.packages = const [],
    this.priceOnQuote = false,
  });

  bool get hasPackages => packages.isNotEmpty;
  bool get hasDurations => durations.isNotEmpty;

  String get priceRange {
    if (priceOnQuote) return 'Por cotización';
    if (durations.isEmpty) return '';
    if (durations.length == 1) return durations.first.formattedPrice;
    return '${durations.first.formattedPrice} — ${durations.last.formattedPrice}';
  }
}
