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
    // Create a new map for the database
    final favoriteData = {
      'user_id': userId,
      'crypto_id': coin['id'],
      'crypto_name': coin['name'],
      'crypto_image': coin['image'],
      'current_price': coin['current_price'],
    };

    await supabase.from('favorites').insert(favoriteData);

    // Add the database format to our local list
    _favorites.add(favoriteData);
    notifyListeners();
  }

  Future<void> removeFavorite(String userId, String cryptoId) async {
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('crypto_id', cryptoId);

    // Use the correct key for comparison
    _favorites.removeWhere((favorite) => favorite['crypto_id'] == cryptoId);
    notifyListeners();
  }

  bool isFavorite(String cryptoId) {
    return _favorites.any((favorite) => favorite['crypto_id'] == cryptoId);
  }
}
