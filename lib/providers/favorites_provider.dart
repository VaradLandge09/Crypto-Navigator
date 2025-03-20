import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> get favorites => _favorites;

  void addFavorite(Map<String, dynamic> coin) {
    if (!_favorites.any((item) => item['id'] == coin['id'])) {
      _favorites.add(coin);
      notifyListeners();
    }
  }

  void removeFavorite(Map<String, dynamic> coin) {
    _favorites.removeWhere((item) => item['id'] == coin['id']);
    notifyListeners();
  }

  bool isFavorite(Map<String, dynamic> coin) {
    return _favorites.any((item) => item['id'] == coin['id']);
  }
}
