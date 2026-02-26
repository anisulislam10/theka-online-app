// import 'package:cloud_firestore/cloud_firestore.dart';

// class RequestModel {
//   final String id;
//   final String userId;
//   final String userName;
//   final String userEmail;
//   final String userPhone;
//   final String userProfileImage;
//   final String service;
//   final String subcategory;
//   final String location;
//   final String description;
//   final int price;
//   final String imageUrl;
//   final String requestType; // "Now" or "Anytime"
//   final String status; // "pending", "accepted", "completed", etc.
//   final DateTime createdAt;

//   // Provider details (available after acceptance)
//   final String? providerId;
//   final String? providerName;
//   final String? providerPhone;
//   final String? providerProfileImage;
//   final String? providerCategory;
//   final DateTime? acceptedAt;

//   RequestModel({
//     required this.id,
//     required this.userId,
//     required this.userName,
//     required this.userEmail,
//     required this.userPhone,
//     required this.userProfileImage,
//     required this.service,
//     required this.subcategory,
//     required this.location,
//     required this.description,
//     required this.price,
//     required this.imageUrl,
//     required this.requestType,
//     required this.status,
//     required this.createdAt,
//     this.providerId,
//     this.providerName,
//     this.providerPhone,
//     this.providerProfileImage,
//     this.providerCategory,
//     this.acceptedAt,
//   });

//   // Factory constructor to create a RequestModel from Firestore document
//   factory RequestModel.fromFirestore(DocumentSnapshot doc, String requestType) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

//     return RequestModel(
//       id: doc.id,
//       userId: data['userId'] ?? '',
//       userName: data['userName'] ?? 'Unknown User',
//       userEmail: data['userEmail'] ?? '',
//       userPhone: data['userPhone'] ?? '',
//       userProfileImage: data['profileImage'] ?? data['userProfileImage'] ?? '',
//       service: data['service'] ?? 'Service',
//       subcategory: data['subcategory'] ?? 'General',
//       location: data['location'] ?? 'Location not specified',
//       description: data['description'] ?? '',
//       price: data['price'] ?? 0,
//       imageUrl: data['imageUrl'] ?? '',
//       requestType: requestType,
//       status: data['status'] ?? 'pending',
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       providerId: data['providerId'],
//       providerName: data['providerName'],
//       providerPhone: data['providerPhone'],
//       providerProfileImage: data['providerProfileImage'],
//       providerCategory: data['providerCategory'],
//       acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
//     );
//   }

//   // Factory constructor from Map
//   factory RequestModel.fromMap(
//       Map<String, dynamic> data, String id, String requestType) {
//     return RequestModel(
//       id: id,
//       userId: data['userId'] ?? '',
//       userName: data['userName'] ?? 'Unknown User',
//       userEmail: data['userEmail'] ?? '',
//       userPhone: data['userPhone'] ?? '',
//       userProfileImage: data['profileImage'] ?? data['userProfileImage'] ?? '',
//       service: data['service'] ?? 'Service',
//       subcategory: data['subcategory'] ?? 'General',
//       location: data['location'] ?? 'Location not specified',
//       description: data['description'] ?? '',
//       price: data['price'] ?? 0,
//       imageUrl: data['imageUrl'] ?? '',
//       requestType: requestType,
//       status: data['status'] ?? 'pending',
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       providerId: data['providerId'],
//       providerName: data['providerName'],
//       providerPhone: data['providerPhone'],
//       providerProfileImage: data['providerProfileImage'],
//       providerCategory: data['providerCategory'],
//       acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
//     );
//   }

//   // Convert to Map for Firestore (for creating new request)
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'userName': userName,
//       'userEmail': userEmail,
//       'userPhone': userPhone,
//       'profileImage': userProfileImage,
//       'service': service,
//       'subcategory': subcategory,
//       'location': location,
//       'description': description,
//       'price': price,
//       'imageUrl': imageUrl,
//       'status': status,
//       'createdAt': Timestamp.fromDate(createdAt),
//       if (providerId != null) 'providerId': providerId,
//       if (providerName != null) 'providerName': providerName,
//       if (providerPhone != null) 'providerPhone': providerPhone,
//       if (providerProfileImage != null)
//         'providerProfileImage': providerProfileImage,
//       if (providerCategory != null) 'providerCategory': providerCategory,
//       if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
//     };
//   }

//   // Convert to Map for UI display (with all fields including derived ones)
//   Map<String, dynamic> toDisplayMap() {
//     return {
//       'id': id,
//       'userId': userId,
//       'userName': userName,
//       'userEmail': userEmail,
//       'userPhone': userPhone,
//       'userProfileImage': userProfileImage,
//       'service': service,
//       'subcategory': subcategory,
//       'location': location,
//       'description': description,
//       'price': price,
//       'imageUrl': imageUrl,
//       'requestType': requestType,
//       'status': status,
//       'createdAt': createdAt,
//       if (providerId != null) 'providerId': providerId,
//       if (providerName != null) 'providerName': providerName,
//       if (providerPhone != null) 'providerPhone': providerPhone,
//       if (providerProfileImage != null)
//         'providerProfileImage': providerProfileImage,
//       if (providerCategory != null) 'providerCategory': providerCategory,
//       if (acceptedAt != null) 'acceptedAt': acceptedAt,
//     };
//   }

//   // CopyWith method for immutability
//   RequestModel copyWith({
//     String? id,
//     String? userId,
//     String? userName,
//     String? userEmail,
//     String? userPhone,
//     String? userProfileImage,
//     String? service,
//     String? subcategory,
//     String? location,
//     String? description,
//     int? price,
//     String? imageUrl,
//     String? requestType,
//     String? status,
//     DateTime? createdAt,
//     String? providerId,
//     String? providerName,
//     String? providerPhone,
//     String? providerProfileImage,
//     String? providerCategory,
//     DateTime? acceptedAt,
//   }) {
//     return RequestModel(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       userName: userName ?? this.userName,
//       userEmail: userEmail ?? this.userEmail,
//       userPhone: userPhone ?? this.userPhone,
//       userProfileImage: userProfileImage ?? this.userProfileImage,
//       service: service ?? this.service,
//       subcategory: subcategory ?? this.subcategory,
//       location: location ?? this.location,
//       description: description ?? this.description,
//       price: price ?? this.price,
//       imageUrl: imageUrl ?? this.imageUrl,
//       requestType: requestType ?? this.requestType,
//       status: status ?? this.status,
//       createdAt: createdAt ?? this.createdAt,
//       providerId: providerId ?? this.providerId,
//       providerName: providerName ?? this.providerName,
//       providerPhone: providerPhone ?? this.providerPhone,
//       providerProfileImage: providerProfileImage ?? this.providerProfileImage,
//       providerCategory: providerCategory ?? this.providerCategory,
//       acceptedAt: acceptedAt ?? this.acceptedAt,
//     );
//   }

//   // Helper getters
//   bool get isAccepted => status == 'accepted';
//   bool get isPending => status == 'pending';
//   bool get isCompleted => status == 'completed';
//   bool get hasProvider => providerId != null && providerId!.isNotEmpty;
// }
