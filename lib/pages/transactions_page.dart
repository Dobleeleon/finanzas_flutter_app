// lib/pages/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/filter_modal.dart';

class TransactionsPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String coupleId;
  final Map<String, dynamic> coupleData;

  const TransactionsPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.coupleId,
    required this.coupleData,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  String _filterType = 'all';
  String _selectedCategory = 'all';
  String _selectedDateFilter = 'all';
  double _minAmount = 0;
  double _maxAmount = 10000000;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categoryOptions = [
    'all', 'Comida', 'Transporte', 'Entretenimiento', 
    'Salud', 'Educación', 'Hogar', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseService.getTransactions(widget.coupleId);
      
      if (result['success']) {
        final transactions = result['data'] as List<dynamic>;
        
        final sortedTransactions = transactions.cast<Map<String, dynamic>>().toList()
          ..sort((a, b) {
            final dateA = _parseTimestamp(a['date'] ?? a['createdAt']);
            final dateB = _parseTimestamp(b['date'] ?? b['createdAt']);
            return dateB.compareTo(dateA);
          });
        
        setState(() {
          _transactions.clear();
          _transactions.addAll(sortedTransactions);
          _applyFilters();
          _isLoading = false;
        });
      } else {
        _showError(result['error'] ?? 'Error al cargar transacciones');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error al cargar transacciones');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_transactions);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final description = transaction['description']?.toString().toLowerCase() ?? '';
        final category = transaction['category']?.toString().toLowerCase() ?? '';
        final userName = transaction['userName']?.toString().toLowerCase() ?? '';
        
        return description.contains(_searchQuery.toLowerCase()) ||
               category.contains(_searchQuery.toLowerCase()) ||
               userName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filterType != 'all') {
      filtered = filtered.where((transaction) => transaction['type'] == _filterType).toList();
    }

    if (_selectedCategory != 'all') {
      filtered = filtered.where((transaction) => transaction['category'] == _selectedCategory).toList();
    }

    // ✅ AGREGAR FILTRADO POR FECHAS
    if (_selectedDateFilter == 'custom' && _startDate != null && _endDate != null) {
      filtered = filtered.where((transaction) {
        final transactionDate = _parseTimestamp(transaction['date'] ?? transaction['createdAt']);
        return transactionDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedDateFilter != 'all' && _selectedDateFilter != 'custom') {
      filtered = _filterByDateRange(filtered, _selectedDateFilter);
    }

    filtered = filtered.where((transaction) {
      final amount = (transaction['amount'] ?? 0.0).toDouble();
      return amount >= _minAmount && amount <= _maxAmount;
    }).toList();

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  List<Map<String, dynamic>> _filterByDateRange(List<Map<String, dynamic>> transactions, String dateFilter) {
    final now = DateTime.now();
    DateTime startDate;

    switch (dateFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return transactions;
    }

    return transactions.where((transaction) {
      final transactionDate = _parseTimestamp(transaction['date'] ?? transaction['createdAt']);
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'all';
      _selectedCategory = 'all';
      _selectedDateFilter = 'all';
      _minAmount = 0;
      _maxAmount = 10000000;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        categories: _categoryOptions,
        selectedCategory: _selectedCategory,
        selectedDateFilter: _selectedDateFilter,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        startDate: _startDate,
        endDate: _endDate,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
          });
          _applyFilters();
        },
        onDateFilterChanged: (dateFilter) {
          setState(() {
            _selectedDateFilter = dateFilter;
          });
          _applyFilters();
        },
        onAmountRangeChanged: (min, max) {
          setState(() {
            _minAmount = min;
            _maxAmount = max;
          });
          _applyFilters();
        },
        onDateRangeChanged: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
          _applyFilters();
        },
        onResetFilters: _resetFilters,
        resultsCount: _filteredTransactions.length,
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        coupleId: widget.coupleId,
        userId: widget.userId,
        userName: widget.userName,
        onTransactionAdded: _loadTransactions,
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      final result = await FirebaseService.deleteTransaction(transactionId);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadTransactions();
      } else {
        _showError(result['error'] ?? 'Error al eliminar transacción');
      }
    } catch (e) {
      _showError('Error al eliminar transacción');
    }
  }

  void _showDeleteDialog(Map<String, dynamic> transaction) {
    final description = transaction['description'] ?? 'Transacción sin nombre';
    final amount = _formatCurrency((transaction['amount'] ?? 0).toDouble());
    final type = transaction['type'] == 'income' ? 'Ingreso' : 'Gasto';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres eliminar esta transacción?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.texto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: transaction['type'] == 'income' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: transaction['type'] == 'income' ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: TextStyle(
                          color: transaction['type'] == 'income' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction['id'] as String);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  String _getUserDisplayName(Map<String, dynamic> transaction) {
    final currentUserId = widget.userId;
    final transactionUserId = transaction['userId'];
    final transactionUserName = transaction['userName'] ?? 'Usuario';
    
    if (transactionUserId == currentUserId) {
      return 'Tú';
    } else {
      return transactionUserName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Transacciones'),
        backgroundColor: AppTheme.card1Fondo,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            color: AppTheme.botonesFondo,
            onPressed: _showFilterModal,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppTheme.botonesFondo,
            onPressed: _loadTransactions,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _buildQuickFilters(),
                _buildSearchBar(),
                _buildSummary(),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return _buildTransactionItem(transaction);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: AppTheme.botonesFondo,
        foregroundColor: AppTheme.botonesTexto,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _filterType == 'all',
              onSelected: (selected) {
                setState(() {
                  _filterType = 'all';
                });
                _applyFilters();
              },
              selectedColor: AppTheme.botonesFondo,
              labelStyle: TextStyle(
                color: _filterType == 'all' 
                    ? AppTheme.botonesTexto 
                    : AppTheme.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Ingresos'),
              selected: _filterType == 'income',
              onSelected: (selected) {
                setState(() {
                  _filterType = 'income';
                });
                _applyFilters();
              },
              selectedColor: Colors.green,
              labelStyle: TextStyle(
                color: _filterType == 'income' 
                    ? Colors.white 
                    : AppTheme.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Gastos'),
              selected: _filterType == 'expense',
              onSelected: (selected) {
                setState(() {
                  _filterType = 'expense';
                });
                _applyFilters();
              },
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: _filterType == 'expense' 
                    ? Colors.white 
                    : AppTheme.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Buscar transacciones...',
          prefixIcon: Icon(Icons.search, color: AppTheme.texto.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.botonesFondo),
          ),
          filled: true,
          fillColor: AppTheme.card1Fondo,
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalIncome = _filteredTransactions
        .where((t) => t['type'] == 'income')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0).toDouble());

    final totalExpenses = _filteredTransactions
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0).toDouble());

    final balance = totalIncome - totalExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: AppTheme.card1Fondo,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Ingresos', totalIncome, Colors.green),
              _buildSummaryItem('Gastos', totalExpenses, Colors.red),
              _buildSummaryItem('Balance', balance, balance >= 0 ? Colors.green : Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.texto,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AppTheme.texto.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterType != 'all' || _selectedCategory != 'all' 
                ? 'Prueba ajustar los filtros'
                : 'Agrega tu primera transacción',
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty || _filterType != 'all' || _selectedCategory != 'all')
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.botonesFondo,
                foregroundColor: AppTheme.botonesTexto,
              ),
              child: const Text('Restablecer filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final isIncome = transaction['type'] == 'income';
    final category = transaction['category'] ?? 'Sin categoría';
    final description = transaction['description'] ?? '';
    final date = transaction['date'] ?? transaction['createdAt'];
    
    final parsedDate = date != null ? _parseTimestamp(date) : DateTime.now();
    final userDisplayName = _getUserDisplayName(transaction);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card1Fondo,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          description.isNotEmpty ? description : category,
          style: TextStyle(
            color: AppTheme.texto,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(parsedDate)} • $category',
              style: TextStyle(
                color: AppTheme.texto.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Por: $userDisplayName',
              style: TextStyle(
                color: AppTheme.texto.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(amount),
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isIncome ? 'Ingreso' : 'Gasto',
                  style: TextStyle(
                    color: AppTheme.texto.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(transaction),
              tooltip: 'Eliminar transacción',
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(transaction),
      ),
    );
  }
}

class AddTransactionDialog extends StatefulWidget {
  final String coupleId;
  final String userId;
  final String userName;
  final VoidCallback onTransactionAdded;

  const AddTransactionDialog({
    super.key,
    required this.coupleId,
    required this.userId,
    required this.userName,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Comida';
  bool _isLoading = false;

  final List<String> _categories = [
    'Comida', 'Transporte', 'Entretenimiento', 'Salud', 'Educación', 'Hogar', 'Otros'
  ];

  Future<void> _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final transactionData = {
          'amount': double.parse(_amountController.text),
          'type': _selectedType,
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'userId': widget.userId,
          'userName': widget.userName,
          'date': DateTime.now(),
          'createdAt': FieldValue.serverTimestamp(),
          'coupleId': widget.coupleId,
        };

        final result = await FirebaseService.addTransaction(transactionData, widget.coupleId);
        
        if (result['success']) {
          if (mounted) {
            Navigator.pop(context);
            widget.onTransactionAdded();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transacción agregada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error al agregar transacción'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al agregar transacción'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Transacción'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                  DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  prefixText: '\$',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una cantidad';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.botonesFondo,
            foregroundColor: AppTheme.botonesTexto,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}