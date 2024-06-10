import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:inzultz/providers/ads.dart';

/// A simple app that loads a banner ad.
class BottomAd extends ConsumerStatefulWidget {
  const BottomAd({super.key});

  @override
  BannerExampleState createState() => BannerExampleState();
}

class BannerExampleState extends ConsumerState<BottomAd> {
  static const privacySettingsText = 'Privacy Settings';

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Orientation? _currentOrientation;

  @override
  void initState() {
    super.initState();
    _loadAd();
    ref.watch(googleAdsProvider.notifier).setupMobileAdsSDK();
  }

  @override
  Widget build(BuildContext context) {

    return OrientationBuilder(builder: (context, orientation) {
      if (_currentOrientation != orientation) {
        _isLoaded = false;
        _loadAd();
        _currentOrientation = orientation;
      }
      return Stack(
        children: [
          if (_bannerAd != null && _isLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  // child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
        ],
      );
    });
  }

  /// Loads and shows a banner ad.
  ///
  /// Dimensions of the ad are determined by the width of the screen.
  void _loadAd() async {
    final consentManager = ref.watch(googleAdsProvider.notifier).consentManager;
    final adUnitId = ref.watch(googleAdsProvider.notifier).adUnitId;
    // Only load an ad if the Mobile Ads SDK has gathered consent aligned with
    // the app's configured messages.
    var canRequestAds = await consentManager.canRequestAds();
    if (!canRequestAds) {
      return;
    }

    if (!mounted) {
      return;
    }

    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.sizeOf(context).width.truncate());

    if (size == null) {
      log.warning('Unable to get adaptive banner size.');
      // Unable to get width of anchored banner.
      return;
    }

    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) async {
          await FirebaseAnalytics.instance.logAdImpression(
            adPlatform: Platform.operatingSystem,
            adSource: ad.adUnitId,
          );
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
