class PromotionModel {
  final String id;
  final String code;
  final String description;
  final String type; // 'percentage' hoặc 'fixed_amount'
  final num value;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int totalQuantity;
  final int usedQuantity;
  final num minSpend;
  final num maxDiscount;

  PromotionModel({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.totalQuantity,
    required this.usedQuantity,
    required this.minSpend,
    required this.maxDiscount,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    // Parse rules nếu có
    final rules = json['rules'] ?? {};
    
    return PromotionModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? json['name'] ?? '',
      type: json['type'] ?? 'fixed_amount',
      value: json['value'] ?? 0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] == true || json['status'] == 'active',
      totalQuantity: json['total_quantity'] ?? 0,
      usedQuantity: json['used_quantity'] ?? 0,
      minSpend: rules['min_spend'] ?? 0,
      maxDiscount: rules['max_discount'] ?? 0,
    );
  }
}