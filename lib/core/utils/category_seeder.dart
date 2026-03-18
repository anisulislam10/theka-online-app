import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategorySeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Map<String, List<String>> skilledCategories = {
    'Electrician': [
      'Wiring',
      'Fan Installation',
      'Switch Board Repair',
      'UPS Installation/Repair',
      'Breaker Replacement',
      'General Lighting',
      'Water Pump Repair',
      'Washing Machine Repair'
    ],
    'Plumber': [
      'Pipe Fitting',
      'Tap Repair/Replacement',
      'Motor Installation',
      'Water Tank Cleaning',
      'Geyser Repair/Installation',
      'Drainage Cleaning',
      'Leakage Repair',
      'Sanitary Fitting'
    ],
    'Painter': [
      'Wall Painting (Interior)',
      'Wall Painting (Exterior)',
      'Texture Painting',
      'Wood Polishing',
      'Furniture Polishing',
      'Wall Putty works',
      'Waterproofing'
    ],
    'Carpenter': [
      'Furniture Repair',
      'Door Installation/Repair',
      'Window Installation/Repair',
      'Cabinet Making',
      'Wardrobe Making',
      'Sofa Repair',
      'Lock Installation/Repair'
    ],
    'Welder': [
      'Gate Repair/Making',
      'Window Grill Making',
      'Steel Fabrications',
      'Iron Fence Installation',
      'Stair Railing',
      'Spot Welding'
    ],
    'Solar Panel Technicians': [
      'Solar Panel Installation',
      'Solar Plate Cleaning',
      'Inverter Installation/Setting',
      'Solar Wiring',
      'Battery Maintenance',
      'System Troubleshooting'
    ],
    'Fabricator': [
      'Aluminum Windows',
      'Fiber Sheds',
      'Glass Work',
      'Steel Gates',
      'Office Partitions',
      'Ceiling Work'
    ],
    'AC Services': [
      'AC Installation',
      'AC Repair',
      'AC Maintenance',
      'AC Gas Refill',
      'Split AC Installation',
      'Window AC Installation',
      'AC Deep Cleaning'
    ],
    'CCTV Services': [
      'Home CCTV Installation',
      'Wireless CCTV Setup',
      'IP Camera Installation',
      'CCTV Maintenance'
    ],
    'Tiles Work': [
      'Floor Tiles Installation',
      'Wall Tiles Installation',
      'Bathroom Tiles',
      'Kitchen Tiles',
      'Tile Repair',
      'Tile Replacement',
      'Tile Polishing'
    ],
    'Mason': [
      'Bricklaying',
      'Stone Masonry',
      'Cement Masonry',
      'Wall Masonry',
      'Floor Masonry',
      'Brick Repair',
      'Stone Repair',
      'Tile Setting',
      'Tile Work',
      'Tile Replacement',
      'Tile Polishing'
    ]
  };

  static final Map<String, List<String>> unskilledCategories = {
    'Helper': [
      'General Helper',
      'Loading/Unloading',
      'Construction Helper',
      'Moving Helper',
      'Shop Helper'
    ],
    'Sweeper': [
      'Home Cleaning',
      'Office Cleaning',
      'Street Cleaning',
      'Gutter Cleaning',
      'Washroom Cleaning'
    ],
    'Gardener': [
      'Lawn Mowing',
      'Planting',
      'Trimming/Pruning',
      'Fertilizing',
      'Watering Plants',
      'Garden Maintenance'
    ],
    'Guard': [
      'Security Guard (Day)',
      'Security Guard (Night)',
      'Event Security',
      'Personal Bodyguard'
    ],
    'Aya (Baby Caretaker)': [
      'Baby Sitting (Hourly)',
      'Baby Sitting (Full Day)',
      'Elderly Care',
      'Patient Care'
    ],
    'Delivery Services': [
      'Package Delivery',
      'Food Delivery',
      'Courier Services'
    ],
    'Cleaner': [
      'Home Deep Cleaning',
      'Office Cleaning',
      'Window Cleaning',
      'Car Cleaning'
    ]
  };

  static Future<void> seedCategories() async {
    try {
      debugPrint('🌱 Starting Category Seeding...');

      // Seed Skilled Categories
      for (var entry in skilledCategories.entries) {
        final categoryName = entry.key;
        final subcategories = entry.value;

        await _firestore
            .collection('ServiceCategories')
            .doc('Skilled')
            .collection(categoryName)
            .doc(categoryName)
            .set({
          'name': categoryName,
          'type': 'Skilled',
          'subcategories': subcategories,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Seeded Skilled: $categoryName');
      }

      // Seed Unskilled Categories
      for (var entry in unskilledCategories.entries) {
        final categoryName = entry.key;
        final subcategories = entry.value;

        await _firestore
            .collection('ServiceCategories')
            .doc('Unskilled')
            .collection(categoryName)
            .doc(categoryName)
            .set({
          'name': categoryName,
          'type': 'Unskilled',
          'subcategories': subcategories,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Seeded Unskilled: $categoryName');
      }

      debugPrint('🎉 Category Seeding Completed Successfully!');
    } catch (e) {
      debugPrint('❌ Error Seeding Categories: $e');
    }
  }
}