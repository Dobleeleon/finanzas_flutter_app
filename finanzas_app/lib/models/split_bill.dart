class SplitBill {
  final String id;
  final String description;
  final double totalAmount;
  final List<dynamic> participants;
  final dynamic paidBy;
  final DateTime date;
  final String? groupId;

  SplitBill({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.participants,
    required this.paidBy,
    required this.date,
    this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'totalAmount': totalAmount,
      'participants': participants.map((p) => p is Map ? p : p.toMap()).toList(),
      'paidBy': paidBy is Map ? paidBy : paidBy?.toMap(),
      'date': date.millisecondsSinceEpoch,
      'groupId': groupId,
    };
  }

  factory SplitBill.fromMap(Map<String, dynamic> map) {
    return SplitBill(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      participants: map['participants'] ?? [],
      paidBy: map['paidBy'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      groupId: map['groupId'],
    );
  }
}
