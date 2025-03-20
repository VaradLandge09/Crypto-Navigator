import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favorites = Provider.of<FavoritesProvider>(context).favorites;

    return Scaffold(
      appBar: AppBar(title: Text("Favorites")),
      body: favorites.isEmpty
          ? Center(child: Text("No favorites added yet!"))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final coin = favorites[index];
                return Card(
                  child: ListTile(
                    leading:
                        Image.network(coin['image'], width: 40, height: 40),
                    title: Text(coin['name']),
                    subtitle: Text('Price: \$${coin['current_price']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Provider.of<FavoritesProvider>(context, listen: false)
                            .removeFavorite(coin);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
