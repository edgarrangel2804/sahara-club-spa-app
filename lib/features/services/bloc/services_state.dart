import 'package:equatable/equatable.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<SpaService> all;
  final List<SpaService> filtered;
  final ServiceCategory? selectedCategory;

  const ServicesLoaded({
    required this.all,
    required this.filtered,
    this.selectedCategory,
  });

  ServicesLoaded copyWith({
    List<SpaService>? filtered,
    ServiceCategory? selectedCategory,
    bool clearCategory = false,
  }) =>
      ServicesLoaded(
        all: all,
        filtered: filtered ?? this.filtered,
        selectedCategory: clearCategory ? null : selectedCategory ?? this.selectedCategory,
      );

  @override
  List<Object?> get props => [all, filtered, selectedCategory];
}
