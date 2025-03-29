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
      appBar: AppBar(title: Text('Favorites')),
      body: favoritesProvider.favorites.isEmpty
          ? Center(child: Text("No favorites added yet!"))
          : ListView.builder(
              itemCount: favoritesProvider.favorites.length,
              itemBuilder: (context, index) {
                final coin = favoritesProvider.favorites[index];

                return Card(
                  child: ListTile(
                    leading: Image.network(coin['crypto_image'],
                        width: 40, height: 40),
                    title: Text(coin['crypto_name']),
                    subtitle: Text('Price: \$${coin['current_price']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null) {
                          favoritesProvider.removeFavorite(
                              user.id, coin['crypto_id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
