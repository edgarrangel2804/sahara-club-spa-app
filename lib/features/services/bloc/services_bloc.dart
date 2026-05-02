import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sahara_club_spa_app/data/models/services_data.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  ServicesBloc() : super(ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServicesCategorySelected>(_onCategorySelected);
  }

  void _onLoad(ServicesLoadRequested event, Emitter<ServicesState> emit) {
    emit(ServicesLoaded(all: allServices, filtered: allServices));
  }

  void _onCategorySelected(ServicesCategorySelected event, Emitter<ServicesState> emit) {
    if (state is! ServicesLoaded) return;
    final current = state as ServicesLoaded;

    if (event.category == null || event.category == current.selectedCategory) {
      emit(current.copyWith(filtered: current.all, clearCategory: true));
    } else {
      final filtered = current.all.where((s) => s.category == event.category).toList();
      emit(current.copyWith(filtered: filtered, selectedCategory: event.category));
    }
  }
}
