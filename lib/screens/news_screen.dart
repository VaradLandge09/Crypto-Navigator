import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  late Future<List<dynamic>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchCryptoNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crypto News')),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading news'));
          }

          final articles = snapshot.data!;
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                title: Text(article['title']),
                subtitle: Text(article['source']['name']),
                onTap: () async {
                  final url = article['url'];
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
