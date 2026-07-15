import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('Mobile Ads SDK Initialized');
    } catch (e) {
      debugPrint('Failed to initialize Mobile Ads SDK: $e');
    }
  }

  /// Native Ad Unit ID
  /// Using Test ID for now
  static String get nativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8500075420783419/2381981675';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8500075420783419/2381981675';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
