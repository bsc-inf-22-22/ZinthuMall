// ─────────────────────────────────────────────────────────────────────────────
//  lib/models/product_model.dart
//
//  Mirrors the JSON shape the backend returns for a single product.
//  Share this with your friend — he must return these exact field names.
//
//  Expected JSON from backend:
//  {
//    "id":             1,
//    "title":          "Classic Oxford Shirt",
//    "seller":         "FashionHub MW",
//    "category":       "shirts",
//    "price":          4500.0,
//    "old_price":      6900.0,        ← null if no discount
//    "discount_label": "-35%",        ← null if no discount
//    "image_url":      "https://...", ← null = show fallback icon
//    "rating":         4.5,
//    "reviews":        128,
//    "tag":            "Under MK 20,000",  ← null if none
//    "condition":      "New",         ← "New" | "Used"
//    "in_wishlist":    false          ← true if logged-in user wishlisted it
//  }
// ─────────────────────────────────────────────────────────────────────────────

class Product {
  final int     id;
  final String  title;
  final String  seller;
  final String  category;
  final double  price;
  final double? oldPrice;
  final String? discountLabel;
  final String? imageUrl;
  final double  rating;
  final int     reviews;
  final String? tag;
  final String  condition;
  final bool    inWishlist;

  const Product({
    required this.id,
    required this.title,
    required this.seller,
    required this.category,
    required this.price,
    this.oldPrice,
    this.discountLabel,
    this.imageUrl,
    required this.rating,
    required this.reviews,
    this.tag,
    required this.condition,
    this.inWishlist = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id:            j['id']             as int,
    title:         j['title']          as String,
    seller:        j['seller']         as String,
    category:      j['category']       as String,
    price:         (j['price']         as num).toDouble(),
    oldPrice:      j['old_price']  != null ? (j['old_price']  as num).toDouble() : null,
    discountLabel: j['discount_label'] as String?,
    imageUrl:      j['image_url']      as String?,
    rating:        (j['rating']        as num).toDouble(),
    reviews:       j['reviews']        as int,
    tag:           j['tag']            as String?,
    condition:     j['condition']      as String? ?? 'New',
    inWishlist:    j['in_wishlist']    as bool?   ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'title':          title,
    'seller':         seller,
    'category':       category,
    'price':          price,
    'old_price':      oldPrice,
    'discount_label': discountLabel,
    'image_url':      imageUrl,
    'rating':         rating,
    'reviews':        reviews,
    'tag':            tag,
    'condition':      condition,
    'in_wishlist':    inWishlist,
  };
}