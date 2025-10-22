class User {
  final String id;
  final String name;
  final String email;
  final double monthlyIncome;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'monthlyIncome': monthlyIncome,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      monthlyIncome: map['monthlyIncome'].toDouble(),
    );
  }
}