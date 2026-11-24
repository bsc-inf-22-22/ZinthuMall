import 'package:flutter_test/flutter_test.dart';
import 'package:kachipapa_store/core/providers/cart_provider.dart';
import 'package:kachipapa_store/core/utils/format.dart';
import 'package:kachipapa_store/features/home/data/models/product_model.dart';

ProductModel _product({int id = 1, double price = 4500, int stock = 10}) => ProductModel.fromJson({
      'id': id,
      'name': 'Classic Oxford Shirt',
      'category': 'mens_clothing',
      'price': price,
      'stock': stock,
      'discount': 35,
      'sizes': ['S', 'M'],
      'imageUrl': null,
      'createdAt': '2026-11-24T08:00:00.000Z',
      'updatedAt': '2026-11-24T08:00:00.000Z',
    });

void main() {
  group('formatMK', () {
    test('adds thousands separators', () {
      expect(formatMK(4500), 'MK 4,500');
      expect(formatMK(1250000), 'MK 1,250,000');
      expect(formatMK(0), 'MK 0');
    });
  });

  group('ProductModel.fromJson', () {
    test('parses numeric and string prices from the API', () {
      expect(_product().price, 4500);
      final fromString = ProductModel.fromJson({
        ..._jsonOf(_product()),
        'price': '4500.00',
      });
      expect(fromString.price, 4500);
    });

    test('works out stock status', () {
      expect(_product(stock: 0).stockStatus, 'OUT_OF_STOCK');
      expect(_product(stock: 3).stockStatus, 'LOW_STOCK');
      expect(_product(stock: 20).stockStatus, 'IN_STOCK');
    });
  });

  group('CartNotifier', () {
    test('merges the same product and size, and totals correctly', () {
      final cart = CartNotifier()
        ..setDeliveryRules(fee: 1500, freeThreshold: 10000)
        ..addItem(_product(), size: 'M')
        ..addItem(_product(), size: 'M');
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 9000);
      expect(cart.deliveryFee, 1500);
      expect(cart.total, 10500);
    });

    test('delivery is free above the threshold', () {
      final cart = CartNotifier()
        ..setDeliveryRules(fee: 1500, freeThreshold: 5000)
        ..addItem(_product(), quantity: 2);
      expect(cart.deliveryFee, 0);
    });

    test('an empty cart has no delivery fee', () {
      final cart = CartNotifier()..setDeliveryRules(fee: 1500, freeThreshold: 5000);
      expect(cart.total, 0);
    });
  });
}

Map<String, dynamic> _jsonOf(ProductModel p) => {
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'price': p.price,
      'stock': p.stock,
      'createdAt': p.createdAt.toIso8601String(),
      'updatedAt': p.updatedAt.toIso8601String(),
    };
