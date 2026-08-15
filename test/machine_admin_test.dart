import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin Machine Category Support', () {
    test('normalizes Machine service type to old and new', () {
      String normalizeServiceTypeForCategory(String category, String? raw) {
        final c = category.toLowerCase().trim();
        final v = (raw ?? '').toLowerCase().trim();
        if (c == 'delivery') {
          if (v.contains('sold') || v == 'sell') return 'sold';
          return 'delivered';
        }
        if (c == 'machine') {
          if (v.contains('new')) return 'new';
          return 'old';
        }
        if (v.contains('rent')) return 'rent';
        return 'sell';
      }

      expect(normalizeServiceTypeForCategory('machine', 'old'), 'old');
      expect(normalizeServiceTypeForCategory('machine', 'new'), 'new');
      expect(normalizeServiceTypeForCategory('machine', 'NEW'), 'new');
      expect(normalizeServiceTypeForCategory('machine', null), 'old');
    });

    test('category display mapping converts Machine correctly', () {
      final categoryMapping = {
        'Equipments': 'equipments',
        'Machine': 'machine',
        'Land Services': 'landServices',
      };

      expect(categoryMapping['Machine'], 'machine');
    });
  });
}
