import 'package:flutter/material.dart';

enum ServiceCategory {
  masajes,
  experienciasCorporales,
  faciales,
  facialesPremium,
  tecnologiaFacial,
  moldeoConsciente,
  tecnologiaCorporal,
  experienciasFusionadas,
  saharaHouse,
  colaboraciones,
}

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.masajes:
        return 'Masajes';
      case ServiceCategory.experienciasCorporales:
        return 'Corporales';
      case ServiceCategory.faciales:
        return 'Faciales';
      case ServiceCategory.facialesPremium:
        return 'Faciales Premium';
      case ServiceCategory.tecnologiaFacial:
        return 'Tecnología Facial';
      case ServiceCategory.moldeoConsciente:
        return 'Moldeo Consciente';
      case ServiceCategory.tecnologiaCorporal:
        return 'Tecnología Corporal';
      case ServiceCategory.experienciasFusionadas:
        return 'Fusionadas';
      case ServiceCategory.saharaHouse:
        return 'Sahara House';
      case ServiceCategory.colaboraciones:
        return 'Colaboraciones';
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
      case ServiceCategory.facialesPremium:
        return Icons.auto_fix_high;
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
      case ServiceCategory.colaboraciones:
        return Icons.people_outline;
    }
  }
}

class ServiceDuration {
  final String serviceId;
  final int minutes;
  final double price;

  const ServiceDuration({
    required this.serviceId,
    required this.minutes,
    required this.price,
  });

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

  // Builds a SpaService from one flat DB row (one duration per row).
  // The ServicesBloc groups multiple rows with the same name+category
  // into a single SpaService with multiple durations.
  factory SpaService.fromMap(Map<String, dynamic> m) {
    return SpaService(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      tagline: m['tagline'] as String? ?? '',
      description: m['description'] as String? ?? '',
      category: parseCategory(m['category'] as String? ?? ''),
      durations: [
        ServiceDuration(
          serviceId: m['id'] as String,
          minutes: (m['duration_min'] as num?)?.toInt() ?? 60,
          price: (m['price'] as num?)?.toDouble() ?? 0,
        ),
      ],
      priceOnQuote: m['price_on_quote'] as bool? ?? false,
    );
  }

  static ServiceCategory parseCategory(String raw) => switch (raw) {
    'Masajes'              => ServiceCategory.masajes,
    'Corporales'           => ServiceCategory.experienciasCorporales,
    'Faciales'             => ServiceCategory.faciales,
    'Faciales Premium'     => ServiceCategory.facialesPremium,
    'Fusionadas'           => ServiceCategory.experienciasFusionadas,
    'Moldeo Consciente'    => ServiceCategory.moldeoConsciente,
    'Sahara House'         => ServiceCategory.saharaHouse,
    'Tecnología Corporal'  => ServiceCategory.tecnologiaCorporal,
    'Tecnología Facial'    => ServiceCategory.tecnologiaFacial,
    'Colaboraciones'       => ServiceCategory.colaboraciones,
    _                      => ServiceCategory.masajes,
  };

  bool get hasPackages => packages.isNotEmpty;
  bool get hasDurations => durations.isNotEmpty;

  String get priceRange {
    if (priceOnQuote) return 'Por cotización';
    if (durations.isEmpty) return '';
    if (durations.length == 1) return durations.first.formattedPrice;
    return '${durations.first.formattedPrice} — ${durations.last.formattedPrice}';
  }
}
