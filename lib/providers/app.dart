import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzultz/models/app.dart';

final appProvider = ChangeNotifierProvider<App>((ref) {
  return App();
});