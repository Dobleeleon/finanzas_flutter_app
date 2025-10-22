class SplitBill {
  final String id;
  final String title;
  final double totalAmount;
  final DateTime date;
  final List<Person> people;
  final String? description;

  SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.date,
    required this.people,
    this.description,
  });

  double get splitAmount {
    if (people.isEmpty) return 0;
    return totalAmount / people.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'people': people.map((person) => person.toMap()).toList(),
      'description': description,
    };
  }

  factory SplitBill.fromMap(Map<String, dynamic> map) {
    return SplitBill(
      id: map['id'],
      title: map['title'],
      totalAmount: map['totalAmount'].toDouble(),
      date: DateTime.parse(map['date']),
      people: List<Person>.from(map['people'].map((x) => Person.fromMap(x))),
      description: map['description'],
    );
  }
}