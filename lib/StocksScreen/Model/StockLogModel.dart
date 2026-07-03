class StockLogModel {
  final int? id;
  final transferId;
  final String? userName;
  final String? type;
  final String? transferType;
  final String? productSku;
  final String? branch;
  final int? amount;
  final String? date;
  final String? time;

  StockLogModel({
    this.id,
    this.userName,
    this.type,
    this.transferType,
    this.productSku,
    this.branch,
    this.amount,
    this.date,
    this.time,
    this.transferId,
  });

  factory StockLogModel.fromJson(Map<String, dynamic> json) {
    return StockLogModel(
      id: json['id'],
      userName: json['user']?['name'],
      type: json['type'],
      transferType: json['status'],
      productSku: json['productSku'],
      branch: json['branch'],
      amount: json['amount'],
      date: json['date'],
      time: json['time'],
      transferId: json["transferId"],
    );
  }
}

class StockLogSummary {
  final int totalEntries;
  final int newStockAdded;
  final int transfersMade;

  StockLogSummary({
    this.totalEntries = 0,
    this.newStockAdded = 0,
    this.transfersMade = 0,
  });

  factory StockLogSummary.fromJson(Map<String, dynamic> json) {
    return StockLogSummary(
      totalEntries: json['totalEntries'] ?? 0,
      newStockAdded: json['newStockAdded'] ?? 0,
      transfersMade: json['transfersMade'] ?? 0,
    );
  }
}
