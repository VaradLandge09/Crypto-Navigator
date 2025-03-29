import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  Future<void> _searchCrypto(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> cryptoData = json.decode(response.body);
        setState(() {
          _searchResults = cryptoData
              .where((coin) =>
                  coin['name'].toLowerCase().contains(query.toLowerCase()) ||
                  coin['symbol'].toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Cryptocurrencies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Crypto...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchCrypto(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final coin = _searchResults[index];
                return ListTile(
                  leading: Image.network(coin['image'], width: 40, height: 40),
                  title: Text(coin['name']),
                  subtitle: Text('Price: \$${coin['current_price']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
