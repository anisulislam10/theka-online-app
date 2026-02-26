import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Service Controller (GetX)
class ServiceController extends GetxController {
  var isLoading = false.obs;
  var serviceCategories =
      <String, List<String>>{}.obs; // category -> subcategories
  var selectedService = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchServiceCategories();
  }

  Future<void> fetchServiceCategories() async {
    try {
      isLoading.value = true;
      final snapshot = await FirebaseFirestore.instance
          .collection('ServiceCategories')
          .get();

      final Map<String, List<String>> categories = {};
      for (var doc in snapshot.docs) {
        categories[doc.id] = List<String>.from(doc['subcategories']);
      }

      serviceCategories.value = categories;
    } catch (e) {
      debugPrint("❌ Error fetching categories: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectService(String serviceName) {
    selectedService.value = serviceName;
  }
}
