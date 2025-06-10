// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Add this PortfolioProvider class to your project
// Create a new file: providers/portfolio_provider.dart
class PortfolioProvider with ChangeNotifier {
  List<Map<String, dynamic>> _portfolioEntries = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get portfolioEntries => _portfolioEntries;
  bool get isLoading => _isLoading;

  Future<void> fetchPortfolio(String userId) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('portfolio')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Convert the response to ensure proper types
      _portfolioEntries = (response as List).map((entry) {
        return Map<String, dynamic>.from(entry)
          ..updateAll((key, value) {
            // Convert numeric fields to double
            if (key == 'quantity' || key == 'purchase_price') {
              return (value as num?)?.toDouble() ?? 0.0;
            }
            return value;
          });
      }).toList();
    } catch (e) {
      print('Error fetching portfolio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHolding(
      String userId, Map<String, dynamic> holdingData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('portfolio').insert({
        ...holdingData,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      await fetchPortfolio(userId);
    } catch (e) {
      print('Error adding portfolio entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHolding(
      String holdingId, Map<String, dynamic> updatedData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('portfolio').update(updatedData).eq('id', holdingId);

      // Re-fetch using any available user ID
      if (_portfolioEntries.isNotEmpty) {
        await fetchPortfolio(_portfolioEntries.first['user_id']);
      }
    } catch (e) {
      print('Error updating portfolio entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHolding(String holdingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('portfolio').delete().eq('id', holdingId);

      // Re-fetch using any available user ID
      if (_portfolioEntries.isNotEmpty) {
        await fetchPortfolio(_portfolioEntries.first['user_id']);
      }
    } catch (e) {
      print('Error deleting portfolio entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get portfolio entries for a specific coin
  List<Map<String, dynamic>> getEntriesForCoin(String coinId) {
    return _portfolioEntries
        .where((entry) => entry['crypto_id'] == coinId)
        .toList();
  }

// Calculate total holdings for a specific coin
  double getTotalQuantityForCoin(String coinId) {
    return getEntriesForCoin(coinId)
        .fold(0.0, (sum, entry) => sum + ((entry['quantity'] ?? 0).toDouble()));
  }

// Calculate average purchase price for a specific coin
  double getAveragePurchasePriceForCoin(String coinId) {
    final entries = getEntriesForCoin(coinId);
    if (entries.isEmpty) return 0.0;

    double totalValue = 0.0;
    double totalQuantity = 0.0;

    for (var entry in entries) {
      final quantity = (entry['quantity'] ?? 0).toDouble();
      final price = (entry['purchase_price'] ?? 0).toDouble();

      totalValue += quantity * price;
      totalQuantity += quantity;
    }

    return totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
  }

  // Calculate profit/loss for a specific coin
  Map<String, dynamic> getProfitLossForCoin(
      String coinId, double currentPrice) {
    final entries = getEntriesForCoin(coinId);
    if (entries.isEmpty) return {'amount': 0.0, 'percentage': 0.0};

    final totalQuantity = getTotalQuantityForCoin(coinId);
    final avgPurchasePrice = getAveragePurchasePriceForCoin(coinId);

    final currentValue = totalQuantity * currentPrice;
    final investedValue = totalQuantity * avgPurchasePrice;

    final profitLossAmount = currentValue - investedValue;
    final profitLossPercentage =
        investedValue > 0 ? (profitLossAmount / investedValue) * 100 : 0.0;

    return {'amount': profitLossAmount, 'percentage': profitLossPercentage};
  }

  // Instead of _portfolioEntries, expose this as holdings
  List<Map<String, dynamic>> get holdings => _portfolioEntries;

  // Check if a holding exists for a crypto
  bool isHolding(String cryptoId) {
    return _portfolioEntries.any((entry) => entry['crypto_id'] == cryptoId);
  }

  // Get all holdings for a specific crypto
  List<Map<String, dynamic>> getHoldingsByCryptoId(String cryptoId) {
    return _portfolioEntries
        .where((entry) => entry['crypto_id'] == cryptoId)
        .toList();
  }
}

// Add these methods to your CryptoDetailScreen class
class PortfolioMethods {
  static void showAddToPortfolioDialog(
      BuildContext context, Map<String, dynamic> coin) {
    final currentPrice = coin['current_price'] ?? 0.0;
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController =
        TextEditingController(text: currentPrice.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add ${coin['name']} to Portfolio'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Current market price: \$${currentPrice.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter purchase price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _savePortfolioEntry(
                      context,
                      coin,
                      double.parse(quantityController.text),
                      double.parse(priceController.text));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add to Portfolio'),
            ),
          ],
        );
      },
    );
  }

  static void _savePortfolioEntry(BuildContext context,
      Map<String, dynamic> coin, double quantity, double purchasePrice) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to track your portfolio')),
      );
      return;
    }

    final portfolioEntry = {
      'user_id': user.id,
      'crypto_id': coin['id'],
      'crypto_name': coin['name'],
      'crypto_symbol': coin['symbol'],
      'quantity': quantity,
      'purchase_price': purchasePrice,
    };

    try {
      final portfolioProvider =
          Provider.of<PortfolioProvider>(context, listen: false);
      await portfolioProvider.addHolding(user.id, portfolioEntry);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coin['name']} added to your portfolio')),
      );
    } catch (e) {
      print('Error saving portfolio entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update portfolio. Please try again.')),
      );
    }
  }

  static void showPortfolioBottomSheet(
      BuildContext context, Map<String, dynamic> coin) {
    final portfolioProvider =
        Provider.of<PortfolioProvider>(context, listen: false);
    final entries = portfolioProvider.getEntriesForCoin(coin['id']);
    final totalQuantity = portfolioProvider.getTotalQuantityForCoin(coin['id']);
    final avgPurchasePrice =
        portfolioProvider.getAveragePurchasePriceForCoin(coin['id']);
    final currentPrice = coin['current_price'] ?? 0.0;
    final profitLoss =
        portfolioProvider.getProfitLossForCoin(coin['id'], currentPrice);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.grey[50];

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
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your ${coin['name']} Portfolio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          Navigator.pop(context);
                          showAddToPortfolioDialog(context, coin);
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Summary card
                  if (totalQuantity > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Holdings',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${totalQuantity.toStringAsFixed(4)} ${coin['symbol'].toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Current Value',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${(totalQuantity * currentPrice).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Avg. Purchase Price',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${avgPurchasePrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Profit/Loss',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        profitLoss['amount'] >= 0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: profitLoss['amount'] >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        size: 14,
                                      ),
                                      Text(
                                        '\$${profitLoss['amount'].abs().toStringAsFixed(2)} (${profitLoss['percentage'].abs().toStringAsFixed(2)}%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: profitLoss['amount'] >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${coin['name']} in your portfolio yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showAddToPortfolioDialog(context, coin);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Transaction'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final date = DateTime.parse(entry['created_at']);
                              final formattedDate =
                                  DateFormat('MMM d, yyyy').format(date);

                              return Dismissible(
                                key: Key(entry['id'].toString()),
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
                                  _deletePortfolioEntry(context, entry['id']);
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: cardColor,
                                  child: ListTile(
                                    title: Text(
                                      '${entry['quantity'].toStringAsFixed(4)} ${coin['symbol'].toUpperCase()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Bought at \$${entry['purchase_price'].toStringAsFixed(2)} on $formattedDate',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${(entry['quantity'] * entry['purchase_price']).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          'Investment',
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _editPortfolioEntry(context, coin, entry);
                                    },
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

  static void _editPortfolioEntry(BuildContext context,
      Map<String, dynamic> coin, Map<String, dynamic> entry) {
    final TextEditingController quantityController =
        TextEditingController(text: entry['quantity'].toString());
    final TextEditingController priceController =
        TextEditingController(text: entry['purchase_price'].toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${coin['name']} Transaction'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter purchase price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updatePortfolioEntry(
                      context,
                      entry['id'],
                      double.parse(quantityController.text),
                      double.parse(priceController.text));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  static void _updatePortfolioEntry(BuildContext context, String entryId,
      double quantity, double purchasePrice) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final updates = {
      'user_id': user.id,
      'quantity': quantity,
      'purchase_price': purchasePrice,
    };

    try {
      final portfolioProvider =
          Provider.of<PortfolioProvider>(context, listen: false);
      await portfolioProvider.updateHolding(entryId, updates);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portfolio entry updated')),
      );
    } catch (e) {
      print('Error updating portfolio entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update. Please try again.')),
      );
    }
  }

  static void _deletePortfolioEntry(
      BuildContext context, String entryId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final portfolioProvider =
          Provider.of<PortfolioProvider>(context, listen: false);
      await portfolioProvider.deleteHolding(entryId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } catch (e) {
      print('Error deleting portfolio entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete. Please try again.')),
      );
    }
  }
}

// Add this Widget to your CryptoDetailScreen
class PortfolioSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> coin;

  const PortfolioSummaryWidget({Key? key, required this.coin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final totalQuantity = portfolioProvider.getTotalQuantityForCoin(coin['id']);

    if (totalQuantity <= 0) {
      return const SizedBox.shrink();
    }

    final avgPurchasePrice =
        portfolioProvider.getAveragePurchasePriceForCoin(coin['id']);
    final currentPrice = coin['current_price'] ?? 0.0;
    final profitLoss =
        portfolioProvider.getProfitLossForCoin(coin['id'], currentPrice);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                onPressed: () =>
                    PortfolioMethods.showAddToPortfolioDialog(context, coin),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holdings',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${totalQuantity.toStringAsFixed(4)} ${coin['symbol'].toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Value: \$${(totalQuantity * currentPrice).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Profit/Loss',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        profitLoss['amount'] >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: profitLoss['amount'] >= 0
                            ? Colors.green
                            : Colors.red,
                        size: 14,
                      ),
                      Text(
                        '\$${profitLoss['amount'].abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: profitLoss['amount'] >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profitLoss['percentage'].abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                      color:
                          profitLoss['amount'] >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                PortfolioMethods.showPortfolioBottomSheet(context, coin),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}
