import 'package:crypto_navigator/screens/crypto_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Provider.of<FavoritesProvider>(context, listen: false)
          .fetchFavorites(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      body: favoritesProvider.favorites.isEmpty
          ? Center(child: Text("No favorites added yet!"))
          : ListView.builder(
              itemCount: favoritesProvider.favorites.length,
              itemBuilder: (context, index) {
                final coin = favoritesProvider.favorites[index];

                return Card(
                  child: ListTile(
                    leading: coin['crypto_image'] != null &&
                            coin['crypto_image'].isNotEmpty
                        ? Image.network(coin['crypto_image'],
                            width: 40, height: 40)
                        : Icon(Icons
                            .image_not_supported), // Placeholder if no image
                    title: Text(coin['crypto_name'] ?? 'Unknown Coin'),
                    subtitle:
                        Text('Price: \$${coin['current_price'] ?? 'N/A'}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null && coin['crypto_id'] != null) {
                          favoritesProvider.removeFavorite(
                              user.id, coin['crypto_id']);
                        }
                      },
                    ),
                    onTap: () {
                      final coinData = {
                        'id': coin['crypto_id'],
                        'name': coin['crypto_name'],
                        'image': coin['crypto_image'],
                        'current_price': coin['current_price'],
                        // Add any other fields that CryptoDetailScreen might need
                        // If some fields are missing, provide default values
                        'market_cap': coin['market_cap'] ?? 0,
                        'total_volume': coin['total_volume'] ?? 0,
                        'price_change_percentage_24h':
                            coin['price_change_percentage_24h'] ?? 0.0,
                        'high_24h': coin['high_24h'] ?? 0.0,
                        'low_24h': coin['low_24h'] ?? 0.0,
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CryptoDetailScreen(coin: coinData),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
