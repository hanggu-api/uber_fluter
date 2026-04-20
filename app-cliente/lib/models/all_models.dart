// user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// restaurant_model.dart
class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final double rating;
  final String category;
  final double deliveryFee;
  final int deliveryTime;
  final bool isOpen;
  final List<String> categories;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.rating,
    required this.category,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.isOpen,
    required this.categories,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'],
      rating: (map['rating'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      deliveryFee: (map['delivery_fee'] ?? 0).toDouble(),
      deliveryTime: map['delivery_time'] ?? 0,
      isOpen: map['is_open'] ?? false,
      categories: List<String>.from(map['categories'] ?? []),
    );
  }
}

// product_model.dart
class ProductModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final List<String> images;
  final String? videoUrl;

  ProductModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.images,
    this.videoUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['image_url'],
      category: map['category'] ?? '',
      isAvailable: map['is_available'] ?? true,
      images: List<String>.from(map['images'] ?? []),
      videoUrl: map['video_url'],
    );
  }
}

// post_model.dart - Para rede social
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? productId;
  final String? restaurantId;
  final String content;
  final List<String> images;
  final String? videoUrl;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.productId,
    this.restaurantId,
    required this.content,
    required this.images,
    this.videoUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userAvatar: map['user_avatar'],
      productId: map['product_id'],
      restaurantId: map['restaurant_id'],
      content: map['content'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      videoUrl: map['video_url'],
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: map['is_liked'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// cart_item_model.dart
class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  int quantity;
  final Map<String, dynamic>? options;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.options,
  });

  double get totalPrice => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      productName: map['product_name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['image_url'],
      quantity: map['quantity'] ?? 1,
      options: map['options'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
      'options': options,
    };
  }
}
