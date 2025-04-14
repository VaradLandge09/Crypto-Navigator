import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  final String _apiKey = 'fd60f6b640544a2c993e24d266106189';

  Future<List<dynamic>> fetchCryptoNews() async {
    final url = Uri.parse(
        'https://newsapi.org/v2/everything?q=cryptocurrency&sortBy=publishedAt&language=en&apiKey=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['articles'];
    } else {
      throw Exception('Failed to load news');
    }
  }
}
