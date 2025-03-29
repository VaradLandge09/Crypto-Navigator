import 'package:crypto_navigator/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CryptoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> coin;

  CryptoDetailScreen({required this.coin});

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  List<FlSpot> priceData = [];
  bool isLoading = true;
  String timeFrame = '7d'; // Default time frame
  bool isPredicting = false;
  List<FlSpot> predictionData = [];

  @override
  void initState() {
    super.initState();
    fetchPriceData();
  }

  Future<void> fetchPriceData() async {
    setState(() {
      isLoading = true;
    });

    int days = 7;
    if (timeFrame == '1d') days = 1;
    if (timeFrame == '30d') days = 30;
    if (timeFrame == '90d') days = 90;

    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/${widget.coin['id']}/market_chart?vs_currency=usd&days=$days');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<FlSpot> points = [];
        int index = 0;

        for (var item in data['prices']) {
          double price = item[1].toDouble();
          points.add(FlSpot(index.toDouble(), price));
          index++;
        }

        setState(() {
          priceData = points;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load price data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void generatePrediction() {
    setState(() {
      isPredicting = true;
    });

    // Simulate prediction loading
    Future.delayed(Duration(seconds: 2), () {
      if (priceData.isNotEmpty) {
        // This is a simple mock prediction - in a real app this would use a proper algorithm
        final lastPrice = priceData.last.y;
        final lastIndex = priceData.last.x;

        List<FlSpot> futurePoints = [];
        for (int i = 1; i <= 7; i++) {
          // Simple trend-based prediction algorithm
          double predictedPrice = lastPrice *
              (1 + (widget.coin['price_change_percentage_24h'] / 100) * i / 3);
          futurePoints.add(FlSpot(lastIndex + i, predictedPrice));
        }

        setState(() {
          predictionData = futurePoints;
          isPredicting = false;
        });
      } else {
        setState(() {
          isPredicting = false;
        });
      }
    });
  }

  String formatNumber(dynamic number) {
    return NumberFormat.compact().format(number);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final coin = widget.coin;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    // Calculate the price color based on 24h change
    final Color priceColor =
        (widget.coin['price_change_percentage_24h'] ?? 0) >= 0
            ? Colors.green
            : Colors.red;

    // Calculate min and max for chart
    double minY = 0;
    double maxY = 0;
    final isFavorite = favoritesProvider.isFavorite(coin['id']);

    if (priceData.isNotEmpty) {
      minY = priceData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) *
          0.95;
      maxY = priceData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) *
          1.05;

      // Include prediction data in min/max calculation if available
      if (predictionData.isNotEmpty) {
        final predMinY = predictionData
            .map((spot) => spot.y)
            .reduce((a, b) => a < b ? a : b);
        final predMaxY = predictionData
            .map((spot) => spot.y)
            .reduce((a, b) => a > b ? a : b);

        minY = minY < predMinY ? minY : predMinY * 0.95;
        maxY = maxY > predMaxY ? maxY : predMaxY * 1.05;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.coin['name'] ?? 'Unknown Coin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              if (isFavorite) {
                print('Removing favorite');
                favoritesProvider.removeFavorite(user!.id, coin['id']);
              } else {
                print('adding favorite');
                favoritesProvider.addFavorite(user!.id, coin);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share feature coming soon')));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with coin info
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                widget.coin['image'] ?? 'default_image_url',
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.currency_bitcoin, size: 50),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.coin['name'] ?? 'Unknown Coin',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          widget.coin['symbol']
                                                  ?.toUpperCase() ??
                                              'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Rank #${widget.coin['market_cap_rank'] ?? 'N/A'}",
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "\$${(widget.coin['current_price'] ?? 0).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        widget.coin['price_change_percentage_24h'] >=
                                                0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: priceColor,
                                        size: 16,
                                      ),
                                      Text(
                                        "${widget.coin['price_change_percentage_24h'].toStringAsFixed(2)}%",
                                        style: TextStyle(
                                          color: priceColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        " (24h)",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Chart card
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Price Chart",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Time frame selector
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  for (final period in [
                                    '1d',
                                    '7d',
                                    '30d',
                                    '90d'
                                  ])
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          timeFrame = period;
                                          predictionData =
                                              []; // Clear predictions on timeframe change
                                        });
                                        fetchPriceData();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: timeFrame == period
                                              ? Colors.blue
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          period,
                                          style: TextStyle(
                                            color: timeFrame == period
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Chart
                        Container(
                          height: 200,
                          child: priceData.isEmpty
                              ? Center(child: Text('No data available'))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color:
                                              Colors.grey[300] ?? Colors.grey,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            if (value == minY ||
                                                value == maxY) {
                                              return Text(
                                                '\$${value.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: predictionData.isEmpty
                                        ? priceData.last.x
                                        : predictionData.last.x,
                                    minY: minY,
                                    maxY: maxY,
                                    lineBarsData: [
                                      // Historical data
                                      LineChartBarData(
                                        spots: priceData,
                                        isCurved: true,
                                        color: priceColor,
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              priceColor.withOpacity(0.1),
                                              priceColor.withOpacity(0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      // Prediction data if available
                                      if (predictionData.isNotEmpty)
                                        LineChartBarData(
                                          spots: predictionData,
                                          isCurved: true,
                                          color: Colors.purple,
                                          barWidth: 2,
                                          dotData: FlDotData(show: false),
                                          dashArray: [5, 5],
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.purple.withOpacity(0.1),
                                                Colors.purple.withOpacity(0.0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor:
                                            Colors.blueGrey.withOpacity(0.8),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map((touchedSpot) {
                                            bool isPrediction =
                                                touchedSpot.barIndex == 1;
                                            return LineTooltipItem(
                                              '\$${touchedSpot.y.toStringAsFixed(2)}',
                                              TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: isPrediction
                                                  ? [
                                                      TextSpan(
                                                        text: ' (Predicted)',
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: Colors.white70,
                                                        ),
                                                      )
                                                    ]
                                                  : [],
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Prediction button
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPredicting)
                              ElevatedButton.icon(
                                onPressed: null,
                                icon: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                label: Text('Predicting...'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: predictionData.isEmpty
                                    ? generatePrediction
                                    : () {
                                        setState(() {
                                          predictionData =
                                              []; // Clear predictions
                                        });
                                      },
                                icon: Icon(
                                  predictionData.isEmpty
                                      ? Icons.timeline
                                      : Icons.close,
                                  size: 18,
                                ),
                                label: Text(predictionData.isEmpty
                                    ? 'Generate Price Prediction'
                                    : 'Clear Prediction'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: predictionData.isEmpty
                                      ? Colors.purple
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              ),
                          ],
                        ),
                        if (predictionData.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Prediction based on recent price trends. Not financial advice.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Market stats
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Market Stats",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        buildStatRow(
                          "Market Cap",
                          "\$${formatNumber(widget.coin['market_cap'] ?? 0)}",
                        ),
                        Divider(),
                        buildStatRow(
                          "24h Volume",
                          "\$${formatNumber(widget.coin['total_volume'] ?? 0)}",
                        ),
                        Divider(),
                        buildStatRow(
                          "Circulating Supply",
                          "${formatNumber(widget.coin['circulating_supply'] ?? 0)} ${widget.coin['symbol']?.toUpperCase() ?? 'N/A'}",
                        ),
                        Divider(),
                        buildStatRow(
                          "All-Time High",
                          widget.coin['ath'] != null
                              ? "\$${widget.coin['ath']?.toStringAsFixed(2) ?? 'N/A'}"
                              : "N/A",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Alerts feature coming soon')));
        },
        child: Icon(Icons.notifications),
        tooltip: 'Set Price Alert',
      ),
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
