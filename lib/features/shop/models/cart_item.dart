class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  String get id =>
      product['id']?.toString() ??
      product['name'] as String? ??
      '';
}
