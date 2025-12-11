class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final String assignedTo;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final double? estimatedPrice;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.assignedTo,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.estimatedPrice,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      assignedTo: json['assignedTo'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      estimatedPrice: json['estimatedPrice'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'estimatedPrice': estimatedPrice,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? assignedTo,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? estimatedPrice,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }

  ShoppingItem toggleCompleted() {
    return copyWith(isCompleted: !isCompleted);
  }

  ShoppingItem assignTo(String member) {
    return copyWith(assignedTo: member);
  }

  ShoppingItem updateQuantity(String newQuantity) {
    return copyWith(quantity: newQuantity);
  }
}
