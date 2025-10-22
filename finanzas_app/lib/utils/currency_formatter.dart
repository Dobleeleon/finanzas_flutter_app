class CurrencyFormatter {
  static String format(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  static String formatWithDecimal(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  // Para inputs - remover formato
  static double? parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned);
  }
}