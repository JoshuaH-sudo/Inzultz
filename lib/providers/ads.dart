import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:inzultz/components/consent_manager.dart';
import 'package:logging/logging.dart';

final log = Logger('GoogleAdsProvider');

class GoogleAdsProvider extends ChangeNotifier {
  final consentManager = ConsentManager();
  var isMobileAdsInitializeCalled = false;
  BannerAd? bannerAd;
  bool isLoaded = false;
  Orientation? currentOrientation;

  // Test ad unit ID.
  final String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';
  
  void setupMobileAdsSDK() {
    consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        // Consent not obtained in current session.
        debugPrint(
            "${consentGatheringError.errorCode}: ${consentGatheringError.message}");
      }

      // Attempt to initialize the Mobile Ads SDK.
      _initializeMobileAdsSDK();
    });

    // This sample attempts to load ads using consent obtained in the previous session.
    _initializeMobileAdsSDK();
  }

  /// Initialize the Mobile Ads SDK if the SDK has gathered consent aligned with
  /// the app's configured messages.
  void _initializeMobileAdsSDK() async {
    if (isMobileAdsInitializeCalled) {
      return;
    }

    var canRequestAds = await consentManager.canRequestAds();
    if (canRequestAds) {
      isMobileAdsInitializeCalled = true;

      // Initialize the Mobile Ads SDK.
      MobileAds.instance.initialize();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }
}

final googleAdsProvider = ChangeNotifierProvider<GoogleAdsProvider>((ref) {
  return GoogleAdsProvider();
});
