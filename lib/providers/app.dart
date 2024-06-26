import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('AppProvider');
class App extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  setLoading(bool value) {
    log.info('Setting loading to $value');
    _isLoading = value;
    notifyListeners();
  }
}

final appProvider = ChangeNotifierProvider<App>((ref) {
  return App();
});