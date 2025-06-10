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

  // Define the color palette constants
  final Color deepBlue = const Color(0xFF0D47A1);
  final Color tealAccent = const Color(0xFF03DAC6);
  final Color backgroundDark = const Color(0xFF121212);
  final Color cardBackground = const Color(0xFF1F1F1F);
  final Color priceUp = const Color(0xFF00E676);
  final Color priceDown = const Color(0xFFFF5252);
  final Color textColor = Colors.white;

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
        if (!mounted) return;
        setState(() {
          cryptoData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    // Sort cryptoData by market_cap_rank when loaded
    if (!isLoading && cryptoData.isNotEmpty) {
      cryptoData.sort((a, b) {
        // Handle null market_cap_rank values
        final rankA = a['market_cap_rank'] ?? double.infinity;
        final rankB = b['market_cap_rank'] ?? double.infinity;
        return rankA.compareTo(rankB);
      });
    }

    return Scaffold(
      backgroundColor: backgroundDark,
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: tealAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Loading cryptocurrency data...',
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : cryptoData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.money_off_outlined,
                        size: 64,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cryptocurrency data available',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          refreshCryptoData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepBlue,
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Refresh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    return RefreshIndicator(
                      color: tealAccent,
                      backgroundColor: cardBackground,
                      onRefresh: () async {
                        await refreshCryptoData();
                      },
                      child: ListView.builder(
                        itemCount: cryptoData.length,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        itemBuilder: (context, index) {
                          final coin = cryptoData[index];
                          final isFavorite =
                              favoritesProvider.isFavorite(coin['id']);

                          // Handle price change formatting and color
                          final priceChange =
                              coin['price_change_percentage_24h'];
                          final isPriceUp =
                              priceChange != null && priceChange >= 0;
                          final priceChangeText = priceChange != null
                              ? '${priceChange.toStringAsFixed(2)}%'
                              : 'N/A';
                          final priceChangeColor =
                              isPriceUp ? priceUp : priceDown;

                          // Format current price with commas for thousands
                          final price = coin['current_price'];
                          final formattedPrice = price != null
                              ? '\$${_formatPrice(price)}'
                              : 'N/A';

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: deepBlue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: tealAccent.withOpacity(0.1),
                              highlightColor: tealAccent.withOpacity(0.05),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CryptoDetailScreen(coin: coin),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                                child: Row(
                                  children: [
                                    // Coin image with shimmer loading
                                    Container(
                                      width: 48,
                                      height: 48,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: backgroundDark,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: coin['image'] != null
                                            ? Image.network(
                                                coin['image'],
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: tealAccent
                                                          .withOpacity(0.5),
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (context, _, __) => Icon(
                                                  Icons.image_not_supported,
                                                  color: textColor
                                                      .withOpacity(0.5),
                                                ),
                                              )
                                            : Icon(
                                                Icons.currency_bitcoin,
                                                color: tealAccent,
                                              ),
                                      ),
                                    ),

                                    // Coin details (name, symbol, price)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  coin['name'] ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: deepBlue
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  coin['symbol']
                                                          ?.toUpperCase() ??
                                                      '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                formattedPrice,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isPriceUp
                                                        ? priceUp
                                                            .withOpacity(0.15)
                                                        : priceDown
                                                            .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isPriceUp
                                                            ? Icons.arrow_upward
                                                            : Icons
                                                                .arrow_downward,
                                                        size: 14,
                                                        color: priceChangeColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          priceChangeText,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                priceChangeColor,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (coin['market_cap'] != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Mkt Cap: \$${_formatLargeNumber(coin['market_cap'])}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: textColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Favorite button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isFavorite
                                            ? priceDown.withOpacity(0.1)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 22,
                                          color: isFavorite
                                              ? priceDown
                                              : textColor.withOpacity(0.5),
                                        ),
                                        onPressed: user != null
                                            ? () async {
                                                if (isFavorite) {
                                                  await favoritesProvider
                                                      .removeFavorite(
                                                          user.id, coin['id']);
                                                } else {
                                                  await favoritesProvider
                                                      .addFavorite(
                                                          user.id, coin);
                                                }
                                              }
                                            : () {
                                                // Show login prompt
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: deepBlue,
                                                    content: Text(
                                                      'Please log in to add favorites',
                                                      style: TextStyle(
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    action: SnackBarAction(
                                                      label: 'Log In',
                                                      textColor: tealAccent,
                                                      onPressed: () {
                                                        Navigator.pushNamed(
                                                            context, '/login');
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  // Helper method to format price with commas
  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';

    // Handle different numeric formats
    if (price is int) {
      return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else if (price is double) {
      if (price < 1) {
        // Show more decimal places for small values
        return price.toStringAsFixed(6);
      } else if (price < 10) {
        return price.toStringAsFixed(4);
      } else {
        // Format with commas and 2 decimal places for larger values
        String priceStr = price.toStringAsFixed(2);
        return priceStr.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      }
    }

    return price.toString();
  }

  // Helper method to format large numbers (like market cap)
  String _formatLargeNumber(dynamic number) {
    if (number == null) return 'N/A';

    double value = number is int ? number.toDouble() : number;

    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  // Method to reload data
  Future<void> refreshCryptoData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fetchCryptoData();
    } catch (error) {
      print('Error refreshing data: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
