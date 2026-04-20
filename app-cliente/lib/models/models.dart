class User {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    required this.createdAt,
  });
  
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      phone: map['phone'],
      photoUrl: map['photo_url'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final String? category;
  
  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isOpen = true,
    this.category,
  });
  
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      photoUrl: map['photo_url'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['total_reviews'] ?? 0,
      isOpen: map['is_open'] ?? true,
      category: map['category'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_open': isOpen,
      'category': category,
    };
  }
}

class Product {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final String? videoUrl;
  final String category;
  final bool available;
  final int preparationTime;
  
  Product({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    this.videoUrl,
    required this.category,
    this.available = true,
    this.preparationTime = 30,
  });
  
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0.0).toDouble(),
      photoUrl: map['photo_url'],
      videoUrl: map['video_url'],
      category: map['category'] ?? '',
      available: map['available'] ?? true,
      preparationTime: map['preparation_time'] ?? 30,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'photo_url': photoUrl,
      'video_url': videoUrl,
      'category': category,
      'available': available,
      'preparation_time': preparationTime,
    };
  }
}

class SocialPost {
  final String id;
  final String userId;
  final String? restaurantId;
  final String? productId;
  final String? mediaUrl;
  final String mediaType; // 'image' ou 'video'
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;
  final User? user;
  
  SocialPost({
    required this.id,
    required this.userId,
    this.restaurantId,
    this.productId,
    this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.user,
  });
  
  factory SocialPost.fromMap(Map<String, dynamic> map) {
    return SocialPost(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      restaurantId: map['restaurant_id'],
      productId: map['product_id'],
      mediaUrl: map['media_url'],
      mediaType: map['media_type'] ?? 'image',
      caption: map['caption'],
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: map['is_liked'] ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      user: map['user'] != null ? User.fromMap(map['user']) : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'product_id': productId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'preparing', 'ready', 'on_way', 'delivered', 'cancelled'
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  
  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.createdAt,
    this.deliveredAt,
  });
  
  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((item) => OrderItem.fromMap(item)).toList();
    
    return Order(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      items: items,
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      deliveryAddress: map['delivery_address'],
      deliveryLatitude: map['delivery_latitude']?.toDouble(),
      deliveryLongitude: map['delivery_longitude']?.toDouble(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      deliveredAt: map['delivered_at'] != null 
          ? DateTime.parse(map['delivered_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  
  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
  
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['product_id'] ?? '',
      productName: map['product_name'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (map['total_price'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

class CartItem {
  final Product product;
  int quantity;
  
  CartItem({
    required this.product,
    this.quantity = 1,
  });
  
  double get totalPrice => product.price * quantity;
}
