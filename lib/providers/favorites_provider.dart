import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> get favorites => _favorites;

  final supabase = Supabase.instance.client;

  Future<void> fetchFavorites(String userId) async {
    final response =
        await supabase.from('favorites').select().eq('user_id', userId);

    _favorites = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }

  Future<void> addFavorite(String userId, Map<String, dynamic> coin) async {
    await supabase.from('favorites').insert({
      'user_id': userId,
      'crypto_id': coin['id'],
      'crypto_name': coin['name'],
      'crypto_image': coin['image'],
      'current_price': coin['current_price'],
    });

    _favorites.add(coin);
    notifyListeners();
  }

  Future<void> removeFavorite(String userId, String cryptoId) async {
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('crypto_id', cryptoId);

    _favorites.removeWhere((coin) => coin['id'] == cryptoId);
    notifyListeners();
  }

  bool isFavorite(String cryptoId) {
    return _favorites.any((coin) => coin['crypto_id'] == cryptoId);
  }
}
