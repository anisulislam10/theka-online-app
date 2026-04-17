import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String title;
  final String description;
  final String details;
  final String link;
  final String bgColor;
  final String textColor;
  final double height;
  final double width;
  final int clicks;
  final int impressions;
  final bool isActive;
  final String position;
  final String companyLogo;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    required this.link,
    required this.bgColor,
    required this.textColor,
    required this.height,
    required this.width,
    required this.clicks,
    required this.impressions,
    required this.isActive,
    required this.position,
    required this.companyLogo,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      details: data['details'] ?? '',
      link: data['link'] ?? '',
      bgColor: data['bgColor'] ?? '#FFFFFF',
      textColor: data['textColor'] ?? '#000000',
      height: (data['height'] ?? 50).toDouble(),
      width: (data['width'] ?? 300).toDouble(),
      clicks: data['clicks'] ?? 0,
      impressions: data['impressions'] ?? 0,
      isActive: data['isActive'] ?? false,
      position: data['position'] ?? 'mobile',
      companyLogo: data['companyLogo'] ?? '',
    );
  }
}
