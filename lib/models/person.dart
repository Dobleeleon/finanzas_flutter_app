class Person {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool hasPaid;

  Person({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.hasPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'hasPaid': hasPaid,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      hasPaid: map['hasPaid'],
    );
  }
}