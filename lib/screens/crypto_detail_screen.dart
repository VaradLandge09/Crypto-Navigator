// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_key_in_widget_constructors, avoid_print, use_build_context_synchronously, prefer_const_constructors, sized_box_for_whitespace, dead_code, sort_child_properties_last

import 'dart:async';

import 'package:crypto_navigator/providers/favorites_provider.dart';
import 'package:crypto_navigator/providers/portfolio_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define color constants based on your palette
const Color kPrimaryColor = Color(0xFF0D47A1); // Deep Blue
const Color kAccentColor = Color(0xFF03DAC6); // Teal/Aqua
const Color kDarkBackgroundColor = Color(0xFF121212); // Almost Black
const Color kCardBackgroundColor = Color(0xFF1F1F1F); // Card Background
const Color kPositiveColor = Color(0xFF00E676); // Bright Green
const Color kNegativeColor = Color(0xFFFF5252); // Bright Red
const Color kTextColor = Color(0xFFFFFFFF); // White

class CryptoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> coin;

  const CryptoDetailScreen({required this.coin});

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
  Map<String, dynamic>? currentPredictionData;

  @override
  void initState() {
    super.initState();
    fetchPriceData();
    fetchExistingAlerts();

    Future.microtask(() {
      fetchPortfolioData();
    });
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

  Future<void> fetchPortfolioData() async {
    PortfolioProvider portfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      await portfolioProvider.fetchPortfolio(user.id);
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
                  const Text('Alert me when price goes:'),
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

  Future<void> generatePrediction() async {
    setState(() {
      isPredicting = true;
    });

    try {
      // Replace 'YOUR_RENDER_URL' with your actual Render deployment URL
      final symbol = widget.coin['id']?.toLowerCase() ?? 'bitcoin';
      print(symbol);
      final apiUrl = 'http://localhost:5000/predict/$symbol';
      // final apiUrl = 'https://crypto-predictor-dyi1.onrender.com/predict/$symbol';

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
      });

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Model exists and prediction successful
        final predictionResult = json.decode(response.body);

        if (priceData.isNotEmpty) {
          final lastIndex = priceData.last.x;
          List<FlSpot> futurePoints = [];

          // Handle your API response format
          if (predictionResult['predicted_price'] != null) {
            double predictedPrice =
                predictionResult['predicted_price'].toDouble();
            double currentPrice =
                predictionResult['current_price']?.toDouble() ??
                    widget.coin['current_price'] ??
                    0.0;

            // Generate prediction trend over 7 days
            final dailyChange = (predictedPrice - currentPrice) / 7;

            for (int i = 1; i <= 7; i++) {
              double dayPrice = currentPrice + (dailyChange * i);
              futurePoints.add(FlSpot(lastIndex + i, dayPrice));
            }

            setState(() {
              predictionData = futurePoints;
              currentPredictionData =
                  predictionResult; // Store full prediction data
              isPredicting = false;
            });

            // Show success message with prediction summary
            final changePercentage =
                predictionResult['change_percent']?.toDouble() ?? 0.0;
            final confidence =
                predictionResult['confidence']?.toDouble() ?? 0.0;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Prediction: ${changePercentage >= 0 ? '+' : ''}${changePercentage.toStringAsFixed(2)}% | Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                ),
                backgroundColor:
                    changePercentage >= 0 ? kPositiveColor : kNegativeColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else if (response.statusCode == 202) {
        // Model training started or in progress
        final responseData = json.decode(response.body);
        final status = responseData['status'];
        final message = responseData['message'];
        final trainingInfo = responseData['training_info'];

        setState(() {
          isPredicting = false;
          currentPredictionData = null;
          predictionData = [];
        });

        if (status == 'training_started') {
          // Training just started
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Model Training Started',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    message ??
                        'Training model for ${widget.coin['symbol']?.toUpperCase()}...',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estimated completion: ${responseData['estimated_completion'] ?? '2-5 minutes'}',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Check Status',
                textColor: Colors.white,
                onPressed: () => _checkTrainingStatus(),
              ),
            ),
          );

          // Start polling for training completion
          _startTrainingStatusPolling();
        } else if (status == 'training_in_progress') {
          // Training already in progress
          final progress = trainingInfo?['progress'] ?? 0;
          final trainingMessage =
              trainingInfo?['message'] ?? 'Training in progress...';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress > 0 ? progress / 100 : null,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Training in Progress (${progress}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    trainingMessage,
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please wait a few minutes and try again',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => generatePrediction(),
              ),
            ),
          );
        }
      } else {
        // Other error responses
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Prediction API Error: $e');

      setState(() {
        isPredicting = false;
      });

      // Check if it's a training-related error
      if (e.toString().contains('training') || e.toString().contains('model')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model Training Required',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'AI model for ${widget.coin['symbol']?.toUpperCase()} needs to be trained first.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Start Training',
              textColor: Colors.white,
              onPressed: () => _startManualTraining(),
            ),
          ),
        );
      } else {
        // Fallback to simple prediction if API fails completely
        if (priceData.isNotEmpty) {
          final lastPrice = priceData.last.y;
          final lastIndex = priceData.last.x;

          List<FlSpot> futurePoints = [];
          for (int i = 1; i <= 7; i++) {
            double predictedPrice = lastPrice *
                (1 +
                    (widget.coin['price_change_percentage_24h'] / 100) * i / 3);
            futurePoints.add(FlSpot(lastIndex + i, predictedPrice));
          }

          setState(() {
            predictionData = futurePoints;
            currentPredictionData = null; // Clear prediction data on fallback
            isPredicting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child:
                          Text('Using offline prediction (API unavailable)')),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Failed to generate prediction')),
                ],
              ),
              backgroundColor: kNegativeColor,
            ),
          );
        }
      }
    }
  }

// Add these new methods for training management
  Timer? _trainingPollingTimer;

  void _startTrainingStatusPolling() {
    _trainingPollingTimer?.cancel();
    _trainingPollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkTrainingStatus();
    });
  }

  void _stopTrainingStatusPolling() {
    _trainingPollingTimer?.cancel();
    _trainingPollingTimer = null;
  }

  Future<void> _checkTrainingStatus() async {
    try {
      final symbol = widget.coin['symbol']?.toLowerCase() ?? 'bitcoin';
      final statusUrl =
          'https://crypto-predictor-dyi1.onrender.com/training-status/$symbol';

      final response = await http.get(Uri.parse(statusUrl), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final statusData = json.decode(response.body);
        final trainingInfo = statusData['training_info'];
        final status = trainingInfo['status'];

        if (status == 'completed') {
          _stopTrainingStatusPolling();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Model training completed! Ready for predictions.')),
                ],
              ),
              backgroundColor: kPositiveColor,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Predict',
                textColor: Colors.white,
                onPressed: () => generatePrediction(),
              ),
            ),
          );
        } else if (status == 'failed') {
          _stopTrainingStatusPolling();

          final errorMessage = trainingInfo['error'] ?? 'Training failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Training failed: $errorMessage')),
                ],
              ),
              backgroundColor: kNegativeColor,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (status == 'training') {
          final progress = trainingInfo['progress'] ?? 0;
          final message = trainingInfo['message'] ?? 'Training...';
          print('Training progress: $progress% - $message');
        }
      }
    } catch (e) {
      print('Error checking training status: $e');
    }
  }

  Future<void> _startManualTraining() async {
    try {
      final symbol = widget.coin['symbol']?.toLowerCase() ?? 'bitcoin';
      final trainUrl =
          'https://crypto-predictor-dyi1.onrender.com/train/$symbol';

      final response = await http.post(
        Uri.parse(trainUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'days': 90,
          'epochs': 30,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Training Started',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  responseData['message'] ?? 'Model training initiated',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'Estimated completion: ${responseData['estimated_completion'] ?? '2-5 minutes'}',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Start polling for completion
        _startTrainingStatusPolling();
      } else {
        throw Exception('Failed to start training');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to start training: $e')),
            ],
          ),
          backgroundColor: kNegativeColor,
        ),
      );
    }
  }

// Don't forget to dispose the timer when the widget is disposed
  @override
  void dispose() {
    _stopTrainingStatusPolling();
    super.dispose();
  }

// Enhanced prediction summary with all essential information
  Widget buildPredictionSummary() {
    if (predictionData.isEmpty) return const SizedBox.shrink();

    final currentPrice = currentPredictionData?['current_price']?.toDouble() ??
        widget.coin['current_price'] ??
        0.0;
    final predictedPrice =
        currentPredictionData?['predicted_price']?.toDouble() ??
            predictionData.last.y;
    final changePercentage =
        currentPredictionData?['change_percent']?.toDouble() ??
            ((predictedPrice - currentPrice) / currentPrice * 100);
    final confidence = currentPredictionData?['confidence']?.toDouble() ?? 0.0;
    final direction = currentPredictionData?['direction'] ?? 'unknown';
    final recommendation = currentPredictionData?['recommendation'] ?? 'Hold';
    final predictionMethod =
        currentPredictionData?['prediction_method'] ?? 'Basic';
    final dataPointsUsed = currentPredictionData?['data_points_used'] ?? 0;
    final timestamp = currentPredictionData?['timestamp'];

    final isPositive = changePercentage >= 0;
    final changeAmount = predictedPrice - currentPrice;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
              ? kPositiveColor.withOpacity(0.3)
              : kNegativeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with prediction method and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_graph,
                    color: isPositive ? kPositiveColor : kNegativeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Prediction',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (timestamp != null)
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          // Method and data info
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  predictionMethod.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$dataPointsUsed data points',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Price',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey[500],
                size: 20,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Predicted Price',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${predictedPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPositive ? kPositiveColor : kNegativeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Change indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPositive
                  ? kPositiveColor.withOpacity(0.1)
                  : kNegativeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? kPositiveColor : kNegativeColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isPositive ? '+' : ''}${changePercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? kPositiveColor : kNegativeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${isPositive ? '+' : ''}\$${changeAmount.toStringAsFixed(2)})',
                  style: TextStyle(
                    color: isPositive ? kPositiveColor : kNegativeColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confidence and recommendation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Confidence indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence Level',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey[700],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: confidence,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _getConfidenceColor(confidence),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getConfidenceColor(confidence),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Recommendation badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _getRecommendationColor(recommendation).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getRecommendationColor(recommendation)
                        .withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRecommendationIcon(recommendation),
                      color: _getRecommendationColor(recommendation),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recommendation.toUpperCase(),
                      style: TextStyle(
                        color: _getRecommendationColor(recommendation),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Disclaimer
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Predictions are estimates. Crypto markets are highly volatile. Invest responsibly.',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper methods
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
        return kPositiveColor;
      case 'sell':
        return kNegativeColor;
      case 'hold':
      default:
        return Colors.orange;
    }
  }

  IconData _getRecommendationIcon(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
        return Icons.shopping_cart;
      case 'sell':
        return Icons.sell;
      case 'hold':
      default:
        return Icons.pause;
    }
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
    // Replace the existing theme color definitions
    const isDarkMode = true; // Force dark mode with your new palette
    const scaffoldBackgroundColor = kDarkBackgroundColor;
    const cardBackgroundColor = kCardBackgroundColor;
    const textColor = kTextColor;
    final secondaryTextColor = Colors.grey[400];
    final dividerColor = Colors.grey[800];
    final chipBackgroundColor = Colors.grey[800];

// Calculate the price color based on 24h change
    final Color priceColor =
        (widget.coin['price_change_percentage_24h'] ?? 0) >= 0
            ? kPositiveColor
            : kNegativeColor;

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
        backgroundColor: kPrimaryColor,
        title: Text(
          widget.coin['name'] ?? 'Unknown Coin',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
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
                                          // Find the time frame selector code and update the color
                                          color: timeFrame == period
                                              ? kAccentColor
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
                        buildPredictionSummary(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

// Portfolio Overview Section
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                                "Your Portfolio",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Coin'),
                                onPressed: () =>
                                    PortfolioMethods.showAddToPortfolioDialog(
                                        context, widget.coin),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Consumer<PortfolioProvider>(
                            builder: (context, portfolioProvider, child) {
                              final entries = portfolioProvider
                                  .getEntriesForCoin(widget.coin['id']);
                              final totalQuantity = portfolioProvider
                                  .getTotalQuantityForCoin(widget.coin['id']);
                              final avgPurchasePrice = portfolioProvider
                                  .getAveragePurchasePriceForCoin(
                                      widget.coin['id']);

                              // Safe type conversion for current price
                              final currentPrice = (widget.coin['current_price']
                                      is int)
                                  ? (widget.coin['current_price'] as int)
                                      .toDouble()
                                  : (widget.coin['current_price'] as double?) ??
                                      0.0;

                              final profitLoss =
                                  portfolioProvider.getProfitLossForCoin(
                                      widget.coin['id'], currentPrice);

                              return entries.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              size: 40,
                                              color: secondaryTextColor,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No ${widget.coin['name']} in your portfolio yet',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        // Summary card
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.grey[850]
                                                : Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.blue.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Colors.blue,
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
                                                      'Total Holdings:',
                                                      style: TextStyle(
                                                        color:
                                                            secondaryTextColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${totalQuantity.toStringAsFixed(4)} ${widget.coin['symbol'].toUpperCase()}',
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
                                                    '\$${(totalQuantity * currentPrice).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        (profitLoss['amount']
                                                                        is int
                                                                    ? (profitLoss['amount']
                                                                            as int)
                                                                        .toDouble()
                                                                    : profitLoss[
                                                                            'amount']
                                                                        as double) >=
                                                                0
                                                            ? Icons.arrow_upward
                                                            : Icons
                                                                .arrow_downward,
                                                        color: (profitLoss['amount']
                                                                        is int
                                                                    ? (profitLoss['amount']
                                                                            as int)
                                                                        .toDouble()
                                                                    : profitLoss[
                                                                            'amount']
                                                                        as double) >=
                                                                0
                                                            ? Colors.green
                                                            : Colors.red,
                                                        size: 14,
                                                      ),
                                                      Text(
                                                        '${((profitLoss['percentage'] is int ? (profitLoss['percentage'] as int).toDouble() : profitLoss['percentage'] as double).abs()).toStringAsFixed(2)}%',
                                                        style: TextStyle(
                                                          color: (profitLoss['amount']
                                                                          is int
                                                                      ? (profitLoss['amount']
                                                                              as int)
                                                                          .toDouble()
                                                                      : profitLoss[
                                                                              'amount']
                                                                          as double) >=
                                                                  0
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => PortfolioMethods
                                              .showPortfolioBottomSheet(
                                                  context, widget.coin),
                                          child: const Text(
                                              'View All Transactions'),
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ],
                      ),
                    ),
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
                                // ignore: deprecated_member_use
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
        backgroundColor: kPrimaryColor,
        onPressed: _showAlertsBottomSheet,
        child: const Icon(Icons.notifications_active, color: kTextColor),
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
