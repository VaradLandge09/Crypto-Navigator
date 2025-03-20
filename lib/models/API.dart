import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  // API key = CG-MjDpvhzadU5baUikuxF9EBVe

  static Future<List<dynamic>> getMarkets() async {
    Uri requestPath = Uri.parse(
        "https://api.coingecko.com/api/v3/coins/markets?vs_currency=inr&per_page=10&page=1");

    var response = await http.get(requestPath);
    var decodedResponse = jsonDecode(response.body);

    List<dynamic> markets = decodedResponse as List<dynamic>;
    return markets;
  }
}
