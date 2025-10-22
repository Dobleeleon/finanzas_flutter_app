import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class TransactionsPage extends StatefulWidget {
  final String userName;

  const TransactionsPage({
    super.key,
    required this.userName,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filter = 'Todas'; // 'Todas', 'Ingresos', 'Gastos'

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'title': 'Pago de Nómina',
      'amount': 1200.00,
      'date': DateTime(2024, 1, 15),
      'category': 'Salario',
      'isExpense': false,
    },
    {
      'id': '2',
      'title': 'Supermercado',
      'amount': 85.50,
      'date': DateTime(2024, 1, 14),
      'category': 'Alimentación',
      'isExpense': true,
    },
    {
      'id': '3',
      'title': 'Pago de Luz',
      'amount': 45.80,
      'date': DateTime(2024, 1, 10),
      'category': 'Servicios',
      'isExpense': true,
    },
    {
      'id': '4',
      'title': 'Freelance',
      'amount': 300.00,
      'date': DateTime(2024, 1, 8),
      'category': 'Ingreso Extra',
      'isExpense': false,
    },
    {
      'id': '5',
      'title': 'Gasolina',
      'amount': 35.00,
      'date': DateTime(2024, 1, 5),
      'category': 'Transporte',
      'isExpense': true,
    },
    {
      'id': '6',
      'title': 'Restaurante',
      'amount': 65.00,
      'date': DateTime(2024, 1, 3),
      'category': 'Entretenimiento',
      'isExpense': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == 'Todas') return _transactions;
    
    return _transactions.where((transaction) {
      if (_filter == 'Ingresos') {
        return !transaction['isExpense'];
      } else {
        return transaction['isExpense'];
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: Column(
        children: [
          // Header con filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.card1Fondo,
            child: Column(
              children: [
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transacciones',
                      style: TextStyle(
                        color: AppTheme.texto,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total: \$$_calculateTotal',
                      style: TextStyle(
                        color: AppTheme.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filtros básicos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todas', 'Ingresos', 'Gastos'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _filter = filter;
                            });
                          },
                          backgroundColor: AppTheme.card1Fondo,
                          selectedColor: AppTheme.botonesFondo,
                          labelStyle: TextStyle(
                            color: _filter == filter
                                ? AppTheme.botonesTexto
                                : AppTheme.texto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de transacciones
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.texto.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron transacciones',
                          style: TextStyle(
                            color: AppTheme.texto.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context);
        },
        backgroundColor: AppTheme.botonesFondo,
        foregroundColor: AppTheme.botonesTexto,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    bool isExpense = transaction['isExpense'];
    Color amountColor = isExpense ? Colors.red : Colors.green;
    String type = isExpense ? 'Gasto' : 'Ingreso';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.card1Fondo,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isExpense
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          transaction['title'],
          style: TextStyle(
            color: AppTheme.card1Texto,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction['category'],
              style: TextStyle(
                color: AppTheme.card1Texto.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              _formatDate(transaction['date']),
              style: TextStyle(
                color: AppTheme.card1Texto.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isExpense
                  ? '-\$${transaction['amount']}'
                  : '+\$${transaction['amount']}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get _calculateTotal {
    double total = 0;
    for (var transaction in _filteredTransactions) {
      if (transaction['isExpense']) {
        total -= transaction['amount'];
      } else {
        total += transaction['amount'];
      }
    }
    return total.toStringAsFixed(2);
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Transacción'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}