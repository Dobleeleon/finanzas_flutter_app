class Debt {
  final String id;
  final String title;
  final double originalAmount;
  final double currentAmount;
  final double interestRate; // Tasa de interés mensual
  final DateTime startDate;
  final DateTime? endDate;
  final String creditor; // Acreedor (banco, tienda, etc.)
  final List<Payment> payments;
  final bool isShared; // Compartida entre ambos
  final String? assignedTo; // 'elmer', 'adriana', 'ambos'

  Debt({
    required this.id,
    required this.title,
    required this.originalAmount,
    required this.currentAmount,
    required this.interestRate,
    required this.startDate,
    this.endDate,
    required this.creditor,
    required this.payments,
    this.isShared = true,
    this.assignedTo = 'ambos',
  });

  // Calcular interés acumulado
  double get accumulatedInterest {
    return currentAmount - originalAmount;
  }

  // Calcular meses transcurridos
  int get monthsPassed {
    final now = DateTime.now();
    return ((now.difference(startDate).inDays) / 30).ceil();
  }

  // Calcular próximo pago de interés
  double get nextInterestPayment {
    return currentAmount * (interestRate / 100);
  }

  // Proyectar deuda futura
  double projectedDebt(int months) {
    double projected = currentAmount;
    for (int i = 0; i < months; i++) {
      projected += projected * (interestRate / 100);
    }
    return projected;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'originalAmount': originalAmount,
      'currentAmount': currentAmount,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'creditor': creditor,
      'payments': payments.map((payment) => payment.toMap()).toList(),
      'isShared': isShared,
      'assignedTo': assignedTo,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      title: map['title'],
      originalAmount: map['originalAmount'].toDouble(),
      currentAmount: map['currentAmount'].toDouble(),
      interestRate: map['interestRate'].toDouble(),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      creditor: map['creditor'],
      payments: List<Payment>.from(
          map['payments'].map((x) => Payment.fromMap(x))),
      isShared: map['isShared'],
      assignedTo: map['assignedTo'],
    );
  }
}

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isInterestPayment;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.isInterestPayment = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'isInterestPayment': isInterestPayment,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'],
      isInterestPayment: map['isInterestPayment'] ?? false,
    );
  }
}