
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('AppProvider');
class App extends ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  setLoading(bool value) {
    log.info('Setting loading to $value');
    _isLoading = value;
    notifyListeners();
  }
}