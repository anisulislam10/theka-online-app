import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_model.dart';

class AdController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  RxList<AdModel> ads = <AdModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAds();
  }

  Future<void> fetchAds() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('Ads')
          .where('isActive', isEqualTo: true)
          .get();
          
      ads.value = snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching ads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void trackImpression(String adId) {
    _firestore.collection('Ads').doc(adId).update({
      'impressions': FieldValue.increment(1),
    });
  }

  Future<void> trackClick(AdModel ad) async {
    try {
      _firestore.collection('Ads').doc(ad.id).update({
        'clicks': FieldValue.increment(1),
      });
      
      String urlString = ad.link.trim();
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      
      final url = Uri.parse(urlString);
      print('🔗 Attempting to launch ad URL: $url');
      
      bool launched = false;
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('⚠️ canLaunchUrl returned false, trying launchUrl directly...');
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      
      if (!launched) {
        print('❌ Failed to launch ad URL: $url');
      }
    } catch (e) {
      print('Error tracking click or launching URL: $e');
    }
  }
}
