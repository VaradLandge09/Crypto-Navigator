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
  List<Map<String, dynamic>> priceAlerts = [];
  bool isLoadingAlerts = false;

  @override
  void initState() {
    super.initState();
    fetchPriceData();
    fetchExistingAlerts();
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

  Future<void> fetchExistingAlerts() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    setState(() {
      isLoadingAlerts = true;
    });

    try {
      final response = await supabase
          .from('price_alerts')
          .select()
          .eq('user_id', user.id)
          .eq('coin_id', widget.coin['id'])
          .order('created_at', ascending: false);

      setState(() {
        priceAlerts = List<Map<String, dynamic>>.from(response);
        isLoadingAlerts = false;
      });
    } catch (e) {
      print('Error fetching alerts: $e');
      setState(() {
        isLoadingAlerts = false;
      });
    }
  }

  Future<void> saveAlert(double targetPrice, String alertType) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to set alerts')),
      );
      return;
    }

    final alertData = {
      'user_id': user.id,
      'coin_id': widget.coin['id'],
      'coin_symbol': widget.coin['symbol'],
      'coin_name': widget.coin['name'],
      'current_price': widget.coin['current_price'],
      'target_price': targetPrice,
      'alert_type': alertType,
      'is_triggered': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('price_alerts').insert(alertData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price alert set for ${widget.coin['name']}')),
      );

      // Refresh alerts list
      fetchExistingAlerts();
    } catch (e) {
      print('Error saving alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to set alert. Please try again.')),
      );
    }
  }

  Future<void> deleteAlert(int alertId) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('price_alerts').delete().eq('id', alertId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert deleted successfully')),
      );

      // Refresh alerts list
      fetchExistingAlerts();
    } catch (e) {
      print('Error deleting alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete alert')),
      );
    }
  }

  void _showAddAlertDialog() {
    final currentPrice = widget.coin['current_price'] ?? 0.0;
    final TextEditingController priceController =
        TextEditingController(text: currentPrice.toString());
    String selectedAlertType = 'above'; // Default alert type

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Price Alert for ${widget.coin['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current price: \$${currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  Text('Alert me when price goes:'),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'above',
                        groupValue: selectedAlertType,
                        onChanged: (value) {
                          setState(() {
                            selectedAlertType = value!;
                          });
                        },
                      ),
                      const Text('Above'),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'below',
                        groupValue: selectedAlertType,
                        onChanged: (value) {
                          setState(() {
                            selectedAlertType = value!;
                          });
                        },
                      ),
                      const Text('Below'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Target Price (USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      final targetPrice = double.parse(priceController.text);
                      Navigator.of(context).pop();
                      saveAlert(targetPrice, selectedAlertType);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid price')),
                      );
                    }
                  },
                  child: const Text('Set Alert'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAlertsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price Alerts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_alert),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddAlertDialog();
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: isLoadingAlerts
                        ? const Center(child: CircularProgressIndicator())
                        : priceAlerts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No alerts set for ${widget.coin['name']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showAddAlertDialog();
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Alert'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: priceAlerts.length,
                                itemBuilder: (context, index) {
                                  final alert = priceAlerts[index];
                                  final isAbove =
                                      alert['alert_type'] == 'above';

                                  return Dismissible(
                                    key: Key(alert['id'].toString()),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                      deleteAlert(alert['id']);
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isAbove
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        child: Icon(
                                          isAbove
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: isAbove
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      title: Text(
                                        '${isAbove ? 'Above' : 'Below'} \$${alert['target_price'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Current: \$${widget.coin['current_price'].toStringAsFixed(2)}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            deleteAlert(alert['id']),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void generatePrediction() {
    setState(() {
      isPredicting = true;
    });

    // Simulate prediction loading
    Future.delayed(const Duration(seconds: 2), () {
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
    final isFavorite = favoritesProvider.isFavorite(coin['id']);

    // Theme aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBackgroundColor =
        isDarkMode ? Colors.black : Colors.grey[100];
    final cardBackgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final chipBackgroundColor =
        isDarkMode ? Colors.grey[800] : Colors.grey[200];

    // Calculate the price color based on 24h change
    final Color priceColor =
        (widget.coin['price_change_percentage_24h'] ?? 0) >= 0
            ? Colors.green
            : Colors.red;

    // Calculate min and max for chart
    double minY = 0;
    double maxY = 0;

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
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : null,
        title: Text(
          widget.coin['name'] ?? 'Unknown Coin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              if (user != null) {
                if (isFavorite) {
                  print('Removing favorite');
                  favoritesProvider.removeFavorite(user.id, coin['id']);
                } else {
                  print('adding favorite');
                  favoritesProvider.addFavorite(user.id, coin);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with coin info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: chipBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                widget.coin['image'] ?? 'default_image_url',
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.currency_bitcoin,
                                        size: 50, color: textColor),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.coin['name'] ?? 'Unknown Coin',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: chipBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          widget.coin['symbol']
                                                  ?.toUpperCase() ??
                                              'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Rank #${widget.coin['market_cap_rank'] ?? 'N/A'}",
                                        style: TextStyle(
                                            color: secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                                      color: textColor,
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
                                        style: TextStyle(
                                            color: secondaryTextColor),
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

                  const SizedBox(height: 16),

                  // Chart card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
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
                                color: textColor,
                              ),
                            ),
                            // Time frame selector
                            Container(
                              decoration: BoxDecoration(
                                color: chipBackgroundColor,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: timeFrame == period
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          period,
                                          style: TextStyle(
                                            color: timeFrame == period
                                                ? Colors.white
                                                : textColor,
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
                        const SizedBox(height: 16),
                        // Chart
                        Container(
                          height: 200,
                          child: priceData.isEmpty
                              ? Center(
                                  child: Text(
                                    'No data available',
                                    style: TextStyle(color: secondaryTextColor),
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: dividerColor ?? Colors.grey,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: const AxisTitles(
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
                                                  color: secondaryTextColor,
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
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
                                    backgroundColor: Colors.transparent,
                                    lineBarsData: [
                                      // Historical data
                                      LineChartBarData(
                                        spots: priceData,
                                        isCurved: true,
                                        color: priceColor,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              priceColor.withOpacity(0.3),
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
                                          dotData: const FlDotData(show: false),
                                          dashArray: [5, 5],
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.purple.withOpacity(0.2),
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
                                        tooltipBgColor: isDarkMode
                                            ? Colors.grey[800]!.withOpacity(0.8)
                                            : Colors.blueGrey.withOpacity(0.8),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map((touchedSpot) {
                                            bool isPrediction =
                                                touchedSpot.barIndex == 1;
                                            return LineTooltipItem(
                                              '\$${touchedSpot.y.toStringAsFixed(2)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: isPrediction
                                                  ? [
                                                      const TextSpan(
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPredicting)
                              ElevatedButton.icon(
                                onPressed: null,
                                icon: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                label: const Text('Predicting...'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
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
                                      : isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
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
                                color: secondaryTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Active Alerts Section
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
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
                                "Your Price Alerts",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add_alert),
                                label: const Text('Add New'),
                                onPressed: _showAddAlertDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          isLoadingAlerts
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : priceAlerts.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.notifications_off,
                                              size: 40,
                                              color: secondaryTextColor,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No active alerts for this cryptocurrency',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: priceAlerts
                                          .take(
                                              2) // Show only first 2 alerts in this view
                                          .map((alert) {
                                        final isAbove =
                                            alert['alert_type'] == 'above';
                                        final currentPrice =
                                            widget.coin['current_price'] ?? 0.0;
                                        final targetPrice =
                                            alert['target_price'] ?? 0.0;
                                        final difference =
                                            ((targetPrice - currentPrice) /
                                                    currentPrice *
                                                    100)
                                                .abs()
                                                .toStringAsFixed(1);

                                        return Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 8.0),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.grey[850]
                                                : Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isAbove
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isAbove
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.red
                                                          .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isAbove
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  color: isAbove
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Alert when price goes ${isAbove ? 'above' : 'below'}:',
                                                      style: TextStyle(
                                                        color:
                                                            secondaryTextColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$${targetPrice.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '$difference% ${isAbove ? 'higher' : 'lower'}',
                                                    style: TextStyle(
                                                      color: isAbove
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        deleteAlert(
                                                            alert['id']),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                          if (priceAlerts.length > 2)
                            Center(
                              child: TextButton(
                                onPressed: _showAlertsBottomSheet,
                                child: const Text('View All Alerts'),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Market stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
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
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildStatRow(
                          "Market Cap",
                          "\$${formatNumber(widget.coin['market_cap'] ?? 0)}",
                          textColor,
                          secondaryTextColor!,
                        ),
                        Divider(color: dividerColor),
                        buildStatRow(
                          "24h Volume",
                          "\$${formatNumber(widget.coin['total_volume'] ?? 0)}",
                          textColor,
                          secondaryTextColor!,
                        ),
                        Divider(color: dividerColor),
                        buildStatRow(
                          "Circulating Supply",
                          "${formatNumber(widget.coin['circulating_supply'] ?? 0)} ${widget.coin['symbol']?.toUpperCase() ?? 'N/A'}",
                          textColor,
                          secondaryTextColor!,
                        ),
                        Divider(color: dividerColor),
                        buildStatRow(
                          "All-Time High",
                          widget.coin['ath'] != null
                              ? "\$${widget.coin['ath']?.toStringAsFixed(2) ?? 'N/A'}"
                              : "N/A",
                          textColor,
                          secondaryTextColor!,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: _showAlertsBottomSheet,
        child: const Icon(Icons.notifications_active, color: Colors.white),
        tooltip: 'Manage Price Alerts',
      ),
    );
  }

  Widget buildStatRow(
      String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
