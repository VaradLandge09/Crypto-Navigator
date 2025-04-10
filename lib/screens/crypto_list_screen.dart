import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'crypto_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CryptoListScreen extends StatefulWidget {
  @override
  _CryptoListScreenState createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  List<dynamic> cryptoData = [];
  bool isLoading = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchCryptoData();

    final user = supabase.auth.currentUser;
    if (user != null) {
      Provider.of<FavoritesProvider>(context, listen: false)
          .fetchFavorites(user.id);
    }
  }

  Future<void> fetchCryptoData() async {
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          cryptoData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Prices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCryptoData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<FavoritesProvider>(
              // 👈 Wrap with Consumer
              builder: (context, favoritesProvider, child) {
                return ListView.builder(
                    itemCount: cryptoData.length,
                    // In the ListView.builder of CryptoListScreen
                    itemBuilder: (context, index) {
                      final coin = cryptoData[index];
                      final isFavorite =
                          favoritesProvider.isFavorite(coin['id']);

                      return Card(
                        child: ListTile(
                          leading: Image.network(coin['image'],
                              width: 40, height: 40),
                          title: Text(coin['name']),
                          subtitle: Text(
                              'Price: \$${coin['current_price']} | Change: ${coin['price_change_percentage_24h']?.toStringAsFixed(2) ?? "N/A"}%'),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: user != null
                                ? () async {
                                    if (isFavorite) {
                                      await favoritesProvider.removeFavorite(
                                          user.id, coin['id']);
                                    } else {
                                      await favoritesProvider.addFavorite(
                                          user.id, coin);
                                    }
                                    // No need for setState here since notifyListeners will trigger a rebuild
                                  }
                                : null,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CryptoDetailScreen(coin: coin),
                              ),
                            );
                          },
                        ),
                      );
                    });
              },
            ),
    );
  }
}
