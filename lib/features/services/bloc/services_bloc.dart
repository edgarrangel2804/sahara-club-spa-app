import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  ServicesBloc() : super(ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServicesCategorySelected>(_onCategorySelected);
  }

  Future<void> _onLoad(
      ServicesLoadRequested event, Emitter<ServicesState> emit) async {
    emit(ServicesLoading());
    try {
      final rows = await Supabase.instance.client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('name')
          .order('duration_min');

      // Group flat rows (one per duration) into services with multiple durations.
      final Map<String, SpaService> grouped = {};
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final key = '${row['category']}|${row['name']}';
        final dur = ServiceDuration(
          serviceId: row['id'] as String,
          minutes: (row['duration_min'] as num?)?.toInt() ?? 60,
          price: (row['price'] as num?)?.toDouble() ?? 0,
        );
        if (grouped.containsKey(key)) {
          final existing = grouped[key]!;
          grouped[key] = SpaService(
            id: existing.id,
            name: existing.name,
            tagline: existing.tagline,
            description: existing.description,
            category: existing.category,
            durations: [...existing.durations, dur],
            packages: existing.packages,
            priceOnQuote: existing.priceOnQuote,
          );
        } else {
          grouped[key] = SpaService(
            id: row['id'] as String,
            name: row['name'] as String? ?? '',
            tagline: row['tagline'] as String? ?? '',
            description: row['description'] as String? ?? '',
            category: SpaService.parseCategory(row['category'] as String? ?? ''),
            durations: [dur],
            priceOnQuote: row['price_on_quote'] as bool? ?? false,
          );
        }
      }

      final services = grouped.values.toList();
      emit(ServicesLoaded(all: services, filtered: services));
    } catch (e) {
      debugPrint('ServicesBloc._onLoad: $e');
      emit(ServicesError(message: 'No se pudieron cargar los servicios.'));
    }
  }

  void _onCategorySelected(
      ServicesCategorySelected event, Emitter<ServicesState> emit) {
    if (state is! ServicesLoaded) return;
    final current = state as ServicesLoaded;
    if (event.category == null || event.category == current.selectedCategory) {
      emit(current.copyWith(filtered: current.all, clearCategory: true));
    } else {
      final filtered =
          current.all.where((s) => s.category == event.category).toList();
      emit(current.copyWith(
          filtered: filtered, selectedCategory: event.category));
    }
  }
}
