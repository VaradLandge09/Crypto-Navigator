import 'package:crypto_navigator/models/api.dart';
import 'package:crypto_navigator/models/Cryptocurrency.dart';
import 'package:flutter/material.dart';

class MarketProvider with ChangeNotifier {
  bool isLoading = true;
  List<Cryptocurrency> markets = [];

  void fetchData() async {
    List<dynamic> _markets = await Api.getMarkets();

    List<Cryptocurrency> temp = [];
    for (var market in _markets) {
      Cryptocurrency newCryptocurrency = Cryptocurrency.fromJson(market);
      temp.add(newCryptocurrency);
    }

    markets = temp;
    isLoading = false;
    notifyListeners();
  }
}
