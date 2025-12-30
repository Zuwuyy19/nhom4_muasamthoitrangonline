// ========================= cart_models.dart =========================

class CartItem {
  final String cartKey; // ✅ key trong DB: productId__size__color
  final String productId;
  final String productName;
  final int price;
  final int quantity;
  final String thumbnail;
  final int createdAt;

  // ✅ size/màu (màu = LABEL hiển thị, vd "Black Pink")
  final String? size;
  final String? color;

  CartItem({
    required this.cartKey,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.thumbnail,
    required this.createdAt,
    this.size,
    this.color,
  });

  factory CartItem.fromMap(String cartKey, Map<dynamic, dynamic> map) {
    return CartItem(
      cartKey: cartKey,
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      price: int.tryParse((map['price'] ?? 0).toString()) ?? 0,
      quantity: int.tryParse((map['quantity'] ?? 0).toString()) ?? 0,
      thumbnail: (map['thumbnail'] ?? '').toString(),
      createdAt: int.tryParse((map['createdAt'] ?? 0).toString()) ?? 0,
      size: map['size']?.toString(),
      color: map['color']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'thumbnail': thumbnail,
      'createdAt': createdAt,
      if (size != null && size!.trim().isNotEmpty) 'size': size,
      if (color != null && color!.trim().isNotEmpty) 'color': color,
    };
  }
}

class WishlistItem {
  final String productId;
  final String productName;
  final int price;
  final String thumbnail;
  final String categoryId;
  final int createdAt;

  WishlistItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.thumbnail,
    required this.categoryId,
    required this.createdAt,
  });

  factory WishlistItem.fromMap(String productId, Map<dynamic, dynamic> map) {
    return WishlistItem(
      productId: productId,
      productName: (map['productName'] ?? '').toString(),
      price: int.tryParse((map['price'] ?? 0).toString()) ?? 0,
      thumbnail: (map['thumbnail'] ?? '').toString(),
      categoryId: (map['categoryId'] ?? '').toString(),
      createdAt: int.tryParse((map['createdAt'] ?? 0).toString()) ?? 0,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int price;
  final int quantity;
  final String thumbnail;

  // ✅ lưu size/màu (label)
  final String? size;
  final String? color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.thumbnail,
    this.size,
    this.color,
  });

  factory OrderItem.fromMap(Map<dynamic, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      price: int.tryParse((map['price'] ?? 0).toString()) ?? 0,
      quantity: int.tryParse((map['quantity'] ?? 0).toString()) ?? 0,
      thumbnail: (map['thumbnail'] ?? '').toString(),
      size: map['size']?.toString(),
      color: map['color']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'thumbnail': thumbnail,
      if (size != null && size!.trim().isNotEmpty) 'size': size,
      if (color != null && color!.trim().isNotEmpty) 'color': color,
    };
  }
}

class PaymentInfo {
  final String method;
  final String status;
  final int? paidAt;

  PaymentInfo({
    required this.method,
    required this.status,
    this.paidAt,
  });

  factory PaymentInfo.fromMap(Map<dynamic, dynamic>? map) {
    final data = map ?? <dynamic, dynamic>{};
    return PaymentInfo(
      method: (data['method'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      paidAt: int.tryParse((data['paidAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'status': status,
      if (paidAt != null) 'paidAt': paidAt,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final int totalAmount;
  final String status;
  final int createdAt;
  final List<OrderItem> items;
  final PaymentInfo payment;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.payment,
  });

  factory OrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final itemsRaw = map['items'];
    final items = <OrderItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) items.add(OrderItem.fromMap(item));
      }
    }

    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      totalAmount: int.tryParse((map['totalAmount'] ?? 0).toString()) ?? 0,
      status: (map['status'] ?? '').toString(),
      createdAt: int.tryParse((map['createdAt'] ?? 0).toString()) ?? 0,
      items: items,
      payment: PaymentInfo.fromMap(map['payment'] is Map ? map['payment'] as Map : null),
    );
  }
}
