// =============================================================
// FILE: lib/features/home/data/models/product_model.dart
//
// UPDATED TO MATCH REAL DATABASE:
//   Before (mock):          After (real backend):
//   id: String          →   id: int
//   stockQty: int       →   stock: int
//   originalPrice       →   discount (percentage)
//   isFeatured          →   removed (not in DB)
//   isFlashDeal         →   removed (not in DB)
//   + added: description, sizes[]
//
// The field names here MUST match exactly what the NestJS
// API returns in its JSON response. If they don't match,
// fromJson() will silently set them to null.
// =============================================================

class ProductModel {
  final int     id;           // int not String — matches @PrimaryGeneratedColumn()
  final String  name;
  final String  category;     // 'mens_clothing', 'womens_clothing', 'domestics_home'
  final double  price;
  final int     stock;        // was stockQty — now matches DB column name
  final int?    discount;     // discount % e.g. 20 means 20% off
  final String? description;
  final String? imageUrl;
  final List<String> sizes;   // e.g. ['S', 'M', 'L', 'XL']
  final DateTime createdAt;
  final DateTime updatedAt;

  // Fields not in DB — we keep them for UI display only
  // These are NOT sent to/from the API
  final String sellerName;    // shown on product card
  final double rating;        // shown on product card
  final int    reviewCount;   // shown on product card

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.discount,
    this.description,
    this.imageUrl,
    this.sizes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.sellerName  = 'KachipapaStore',
    this.rating      = 0.0,
    this.reviewCount = 0,
  });

  // ----------------------------------------------------------
  // COMPUTED PROPERTIES
  // ----------------------------------------------------------

  /// True if product has a discount percentage set
  bool get hasDiscount => discount != null && discount! > 0;

  /// Calculate original price from discount %
  /// e.g. price=4500, discount=35 → original = 4500 / (1 - 0.35) = 6923
  double get originalPrice {
    if (!hasDiscount) return price;
    return price / (1 - discount! / 100);
  }

  /// How much the buyer saves in MK
  double get savingsAmount => hasDiscount ? originalPrice - price : 0;

  /// True if product is available to purchase
  bool get inStock => stock > 0;

  /// Stock status label — matches inventory backend logic
  /// IN_STOCK / LOW_STOCK (< 5) / OUT_OF_STOCK (0)
  String get stockStatus {
    if (stock == 0) return 'OUT_OF_STOCK';
    if (stock < 5)  return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  /// Formatted price string — "MK 4,500"
  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'MK $formatted';
  }

  /// Formatted original price — "MK 6,900"
  String get formattedOriginalPrice {
    final formatted = originalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'MK $formatted';
  }

  // ----------------------------------------------------------
  // fromJson — converts API JSON response → ProductModel
  //
  // The backend returns JSON like:
  // {
  //   "id": 1,
  //   "name": "Classic Oxford Shirt",
  //   "category": "mens_clothing",
  //   "price": "4500.00",    ← decimal comes as String from PostgreSQL
  //   "stock": 42,
  //   "discount": 35,
  //   "description": "...",
  //   "sizes": ["S","M","L"],
  //   "imageUrl": "https://...",
  //   "createdAt": "2025-01-10T00:00:00.000Z",
  //   "updatedAt": "2025-01-10T00:00:00.000Z"
  // }
  // ----------------------------------------------------------
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id:          json['id'] as int,
      name:        json['name'] as String,
      category:    json['category'] as String,
      // price comes as String from PostgreSQL decimal type
      price:       double.parse(json['price'].toString()),
      stock:       json['stock'] as int? ?? 0,
      discount:    json['discount'] as int?,
      description: json['description'] as String?,
      imageUrl:    json['imageUrl'] as String?,
      // sizes is stored as 'simple-array' in TypeORM
      // It comes back as a List or null
      sizes: json['sizes'] != null
          ? List<String>.from(json['sizes'] as List)
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // ----------------------------------------------------------
  // toJson — converts ProductModel → JSON for sending TO the API
  // Used when admin creates or updates a product.
  // Note: we DON'T send id, createdAt, updatedAt — the server
  // generates those automatically.
  // ----------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'name':        name,
      'category':    category,
      'price':       price,
      'stock':       stock,
      if (discount    != null) 'discount':    discount,
      if (description != null) 'description': description,
      if (sizes.isNotEmpty)    'sizes':       sizes,
    };
  }

  // ----------------------------------------------------------
  // copyWith — immutable update pattern
  // ----------------------------------------------------------
  ProductModel copyWith({
    int?      id,
    String?   name,
    String?   category,
    double?   price,
    int?      stock,
    int?      discount,
    String?   description,
    String?   imageUrl,
    List<String>? sizes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String?   sellerName,
    double?   rating,
    int?      reviewCount,
  }) {
    return ProductModel(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      category:    category    ?? this.category,
      price:       price       ?? this.price,
      stock:       stock       ?? this.stock,
      discount:    discount    ?? this.discount,
      description: description ?? this.description,
      imageUrl:    imageUrl    ?? this.imageUrl,
      sizes:       sizes       ?? this.sizes,
      createdAt:   createdAt   ?? this.createdAt,
      updatedAt:   updatedAt   ?? this.updatedAt,
      sellerName:  sellerName  ?? this.sellerName,
      rating:      rating      ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  // ----------------------------------------------------------
  // SAMPLE DATA — for UI development & testing
  // These match the exact structure of what the real API returns.
  // Delete these once the real API is running.
  // ----------------------------------------------------------
  static List<ProductModel> sampleProducts = [
    ProductModel(
      id: 1, name: 'Classic Oxford Shirt',
      category: 'mens_clothing', price: 4500, stock: 42,
      discount: 35, description: 'Premium combed cotton Oxford shirt.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      sellerName: 'FashionHub MW', rating: 4.9, reviewCount: 128,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 2, name: 'Floral Wrap Dress',
      category: 'womens_clothing', price: 7200, stock: 18,
      discount: 20, description: 'Elegant floral wrap dress.',
      sizes: ['XS', 'S', 'M', 'L'],
      sellerName: 'StyleQueen', rating: 4.5, reviewCount: 94,
      createdAt: DateTime(2025, 2, 5), updatedAt: DateTime(2025, 2, 5),
    ),
    ProductModel(
      id: 3, name: 'Non-stick Cookware Set',
      category: 'domestics_home', price: 12000, stock: 7,
      description: '5-piece non-stick cookware set.',
      sellerName: 'HomeEssentials', rating: 4.9, reviewCount: 211,
      createdAt: DateTime(2025, 1, 20), updatedAt: DateTime(2025, 1, 20),
    ),
    ProductModel(
      id: 4, name: 'Block Heel Sandals',
      category: 'womens_clothing', price: 5800, stock: 15,
      discount: 40, sizes: ['36', '37', '38', '39', '40'],
      sellerName: 'SoleStyle', rating: 4.3, reviewCount: 67,
      createdAt: DateTime(2025, 3, 1), updatedAt: DateTime(2025, 3, 1),
    ),
    ProductModel(
      id: 5, name: 'Cotton Bedsheet Set',
      category: 'domestics_home', price: 8500, stock: 30,
      description: 'Soft 100% cotton bedsheet set.',
      sellerName: 'DreamHome', rating: 4.8, reviewCount: 183,
      createdAt: DateTime(2025, 2, 14), updatedAt: DateTime(2025, 2, 14),
    ),
    ProductModel(
      id: 6, name: "Men's Bomber Jacket",
      category: 'mens_clothing', price: 18000, stock: 10,
      discount: 15, sizes: ['S', 'M', 'L', 'XL'],
      sellerName: 'UrbanThread', rating: 4.4, reviewCount: 52,
      createdAt: DateTime(2025, 3, 8), updatedAt: DateTime(2025, 3, 8),
    ),
    ProductModel(
      id: 7, name: 'Bathroom Accessory Set',
      category: 'domestics_home', price: 6200, stock: 4,
      description: 'Complete bathroom accessory set.',
      sellerName: 'CleanHome MW', rating: 4.2, reviewCount: 41,
      createdAt: DateTime(2025, 3, 15), updatedAt: DateTime(2025, 3, 15),
    ),
    ProductModel(
      id: 8, name: 'Slim Fit Chinos',
      category: 'mens_clothing', price: 9000, stock: 25,
      sizes: ['28', '30', '32', '34', '36'],
      sellerName: 'TrendyMW', rating: 4.6, reviewCount: 87,
      createdAt: DateTime(2025, 3, 20), updatedAt: DateTime(2025, 3, 20),
    ),
  ];

  // Alias for backward compatibility — same as discount
  int get discountPercent => discount ?? 0;
}
