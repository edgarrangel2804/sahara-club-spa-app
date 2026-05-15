import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class ShopCartController extends ValueNotifier<List<CartItem>> {
  ShopCartController._() : super([]);

  static final ShopCartController instance = ShopCartController._();

  int get itemCount => value.fold(0, (sum, item) => sum + item.quantity);

  void add(Map<String, dynamic> product) {
    final id = product['id']?.toString() ??
        product['name'] as String? ??
        '';
    final idx = value.indexWhere((item) => item.id == id);
    if (idx >= 0) {
      value[idx].quantity++;
      notifyListeners();
    } else {
      value = [...value, CartItem(product: product)];
    }
  }

  void remove(String id) {
    value = value.where((item) => item.id != id).toList();
  }

  void decrementOrRemove(String id) {
    final idx = value.indexWhere((item) => item.id == id);
    if (idx < 0) return;
    if (value[idx].quantity > 1) {
      value[idx].quantity--;
      notifyListeners();
    } else {
      remove(id);
    }
  }

  void clear() {
    value = [];
  }
}
