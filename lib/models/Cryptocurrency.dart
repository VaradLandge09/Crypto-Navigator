class Cryptocurrency {
  String? id;
  String? symbol;
  String? name;
  String? image;
  double? currentprice;
  double? marketCap;
  int? marketCapRank;
  double? high24;
  double? low24;
  double? priceChange24;
  double? priceChangePercentage24;
  double? circulatingSupply;
  double? ath;
  double? atl;

  Cryptocurrency({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentprice,
    required this.marketCap,
    required this.marketCapRank,
    required this.high24,
    required this.low24,
    required this.priceChange24,
    required this.priceChangePercentage24,
    required this.circulatingSupply,
    required this.ath,
    required this.atl,
  });

  factory Cryptocurrency.fromJson(Map<String, dynamic> map) {
    return Cryptocurrency(
        id: map["id"],
        symbol: map["symbol"],
        name: map["name"],
        image: map["image"],
        currentprice: map["current_price"],
        marketCap: map["market_cap"],
        marketCapRank: map["market_cap_rank"],
        high24: map["high_24h"],
        low24: map["low_24h"],
        priceChange24: map["price_change_24h"],
        priceChangePercentage24: map["price_change_percentage_24h"],
        circulatingSupply: map["circulating_supply"],
        ath: map["ath"],
        atl: map["id"]);
  }
}
