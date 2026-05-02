import 'package:equatable/equatable.dart';
import 'package:sahara_club_spa_app/data/models/spa_service.dart';

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class ServicesLoadRequested extends ServicesEvent {
  const ServicesLoadRequested();
}

class ServicesCategorySelected extends ServicesEvent {
  final ServiceCategory? category;
  const ServicesCategorySelected(this.category);
  @override
  List<Object?> get props => [category];
}
