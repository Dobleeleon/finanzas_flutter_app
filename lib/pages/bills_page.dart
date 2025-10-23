// lib/pages/bills_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/filter_modal.dart';

class BillsPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String coupleId;
  final Map<String, dynamic> coupleData;

  const BillsPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.coupleId,
    required this.coupleData,
  });

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _filteredBills = [];
  bool _isLoading = true;
  
  String _filterStatus = 'all';
  String _filterCategory = 'all';
  double _minAmount = 0;
  double _maxAmount = 10000000;

  final List<String> _categoryOptions = [
    'all', 'Servicios', 'Alquiler', 'Préstamos', 'Impuestos', 'Seguros', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FirebaseService.getBills(widget.coupleId);
      
      if (result['success'] == true) {
        final billsData = result['data'] as List<dynamic>;
        
        List<Map<String, dynamic>> bills = billsData.map((bill) {
          final dueDate = bill['dueDate'] != null 
              ? (bill['dueDate'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 30));
              
          return {
            'id': bill['id'],
            'title': bill['description'] ?? 'Sin título',
            'amount': (bill['amount'] ?? 0.0).toDouble(),
            'dueDate': dueDate,
            'category': bill['category'] ?? 'Otros',
            'paid': bill['paid'] ?? false,
            'paidBy': bill['paidBy'] ?? '', // Nuevo campo para saber quién pagó
            'paidByName': bill['paidByName'] ?? '',
            'paidAt': bill['paidAt'] != null ? (bill['paidAt'] as Timestamp).toDate() : null,
            'notes': bill['notes'] ?? '',
            'coupleId': widget.coupleId,
            'userId': bill['userId'] ?? widget.userId,
            'userName': bill['userName'] ?? widget.userName,
          };
        }).toList();

        bills.sort((a, b) {
          final daysA = _getDaysUntilDue(a['dueDate']);
          final daysB = _getDaysUntilDue(b['dueDate']);
          return daysA.compareTo(daysB);
        });

        setState(() {
          _bills = bills;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        throw Exception(result['error'] ?? 'Error al cargar facturas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar facturas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_bills);

    if (_filterStatus != 'all') {
      final isPaid = _filterStatus == 'paid';
      filtered = filtered.where((bill) => bill['paid'] == isPaid).toList();
    }

    if (_filterCategory != 'all') {
      filtered = filtered.where((bill) => bill['category'] == _filterCategory).toList();
    }

    filtered = filtered.where((bill) {
      return bill['amount'] >= _minAmount && bill['amount'] <= _maxAmount;
    }).toList();

    setState(() {
      _filteredBills = filtered;
    });
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

  int _getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  Color _getDueDateColor(int daysUntilDue) {
    if (daysUntilDue < 0) return Colors.red;
    if (daysUntilDue == 0) return Colors.orange;
    if (daysUntilDue <= 3) return Colors.orange.shade600;
    if (daysUntilDue <= 7) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getDueDateText(int daysUntilDue) {
    if (daysUntilDue < 0) return 'Vencida hace ${daysUntilDue.abs()} días';
    if (daysUntilDue == 0) return 'Vence hoy';
    if (daysUntilDue == 1) return 'Vence mañana';
    return 'Vence en $daysUntilDue días';
  }

  String _getUserDisplayName(Map<String, dynamic> bill) {
    final currentUserId = widget.userId;
    final billUserId = bill['userId'];
    final billUserName = bill['userName'] ?? 'Usuario';
    
    if (billUserId == currentUserId) {
      return 'Tú';
    } else {
      return billUserName;
    }
  }

  // NUEVO MÉTODO: Obtener nombre de quién pagó la factura
  String _getPaidByDisplayName(Map<String, dynamic> bill) {
    final paidBy = bill['paidBy'] ?? '';
    final paidByName = bill['paidByName'] ?? '';
    
    if (paidBy.isEmpty) return 'No pagada';
    
    if (paidBy == widget.userId) {
      return 'Pagada por ti';
    } else {
      return 'Pagada por ${paidByName.isNotEmpty ? paidByName : 'pareja'}';
    }
  }

  void _resetFilters() {
    setState(() {
      _filterStatus = 'all';
      _filterCategory = 'all';
      _minAmount = 0;
      _maxAmount = 10000000;
    });
    _applyFilters();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        categories: _categoryOptions.map((category) {
          return category == 'all' ? 'Todas las categorías' : category;
        }).toList(),
        selectedCategory: _filterCategory == 'all' ? 'Todas las categorías' : _filterCategory,
        selectedDateFilter: 'all',
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        onCategoryChanged: (selected) {
          String internalValue;
          if (selected == 'Todas las categorías') {
            internalValue = 'all';
          } else {
            internalValue = selected;
          }
          setState(() {
            _filterCategory = internalValue;
          });
          _applyFilters();
        },
        onDateFilterChanged: (dateFilter) {},
        onAmountRangeChanged: (min, max) {
          setState(() {
            _minAmount = min;
            _maxAmount = max;
          });
          _applyFilters();
        },
        onResetFilters: _resetFilters,
        resultsCount: _filteredBills.length,
      ),
    );
  }

  // MÉTODO CORREGIDO: Usar markBillAsPaid en lugar de updateBill
  Future<void> _toggleBillStatus(String billId, bool currentStatus) async {
    try {
      if (currentStatus) {
        // Si está pagada, marcar como no pagada
        final result = await FirebaseService.markBillAsUnpaid(billId);
        
        if (result['success'] == true) {
          _loadBills();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Factura marcada como pendiente'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          throw Exception(result['error']);
        }
      } else {
        // Si no está pagada, marcar como pagada por el usuario actual
        final result = await FirebaseService.markBillAsPaid(
          billId, 
          widget.userId, 
          widget.userName
        );
        
        if (result['success'] == true) {
          _loadBills();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Factura marcada como pagada'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(result['error']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar factura'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddBillDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    String selectedCategory = 'Servicios';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nueva Factura'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la factura*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto*',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría*',
                      border: OutlineInputBorder(),
                    ),
                    items: _categoryOptions.where((cat) => cat != 'all').map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento*',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(selectedDate)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;

                  if (titleController.text.isEmpty || amount <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor completa los campos obligatorios'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    final billData = {
                      'description': titleController.text,
                      'amount': amount,
                      'category': selectedCategory,
                      'dueDate': selectedDate,
                      'paid': false,
                      'paidBy': '', // Inicialmente vacío
                      'paidByName': '', // Inicialmente vacío
                      'paidAt': null, // Inicialmente nulo
                      'notes': notesController.text,
                      'userId': widget.userId,
                      'userName': widget.userName,
                      'coupleId': widget.coupleId,
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    final result = await FirebaseService.addBill(billData, widget.coupleId);
                    
                    if (result['success'] == true) {
                      _loadBills();
                      Navigator.pop(context);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Factura agregada correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      throw Exception(result['error']);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al agregar factura'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.botonesFondo,
                  foregroundColor: AppTheme.botonesTexto,
                ),
                child: const Text('Agregar Factura'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBill(String billId, String billTitle) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text('¿Estás seguro de que quieres eliminar la factura "$billTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await FirebaseService.deleteBill(billId);
                
                if (result['success'] == true) {
                  _loadBills();
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Factura eliminada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  throw Exception(result['error']);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al eliminar factura'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _filterStatus == 'all',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'all';
                });
                _applyFilters();
              },
              selectedColor: AppTheme.botonesFondo,
              labelStyle: TextStyle(
                color: _filterStatus == 'all' 
                    ? AppTheme.botonesTexto 
                    : AppTheme.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Pagadas'),
              selected: _filterStatus == 'paid',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'paid';
                });
                _applyFilters();
              },
              selectedColor: Colors.green,
              labelStyle: TextStyle(
                color: _filterStatus == 'paid' 
                    ? Colors.white 
                    : AppTheme.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Pendientes'),
              selected: _filterStatus == 'pending',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'pending';
                });
                _applyFilters();
              },
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                color: _filterStatus == 'pending' 
                    ? Colors.white 
                    : AppTheme.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalBills = _filteredBills.length;
    final paidBills = _filteredBills.where((bill) => bill['paid'] == true).length;
    final pendingBills = totalBills - paidBills;
    final totalAmount = _filteredBills.fold(0.0, (sum, bill) => sum + bill['amount']);
    final pendingAmount = _filteredBills
        .where((bill) => bill['paid'] == false)
        .fold(0.0, (sum, bill) => sum + bill['amount']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppTheme.card1Fondo,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total', totalBills.toString(), AppTheme.texto),
                  _buildSummaryItem('Pagadas', paidBills.toString(), Colors.green),
                  _buildSummaryItem('Pendientes', pendingBills.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.texto.withOpacity(0.3)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Monto Total', _formatCurrency(totalAmount), AppTheme.texto),
                  _buildSummaryItem('Por Pagar', _formatCurrency(pendingAmount), Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
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
            'No hay facturas',
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus != 'all' || _filterCategory != 'all' 
                ? 'Prueba ajustar los filtros'
                : 'Agrega tu primera factura',
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          if (_filterStatus != 'all' || _filterCategory != 'all')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Facturas'),
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
            onPressed: _loadBills,
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
                _buildSummary(),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredBills.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadBills,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredBills.length,
                            itemBuilder: (context, index) {
                              final bill = _filteredBills[index];
                              return _buildBillItem(bill);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillDialog,
        backgroundColor: AppTheme.botonesFondo,
        foregroundColor: AppTheme.botonesTexto,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBillItem(Map<String, dynamic> bill) {
    final amount = bill['amount'] ?? 0.0;
    final isPaid = bill['paid'] ?? false;
    final dueDate = bill['dueDate'] as DateTime;
    final daysUntilDue = _getDaysUntilDue(dueDate);
    final dueDateColor = _getDueDateColor(daysUntilDue);
    final dueDateText = _getDueDateText(daysUntilDue);
    final userDisplayName = _getUserDisplayName(bill);
    final paidByDisplayName = _getPaidByDisplayName(bill); // Nuevo: quién pagó

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card1Fondo,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.1) : dueDateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.receipt,
            color: isPaid ? Colors.green : dueDateColor,
            size: 20,
          ),
        ),
        title: Text(
          bill['title'],
          style: TextStyle(
            color: AppTheme.texto,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bill['category']} • ${_formatDate(dueDate)}',
              style: TextStyle(
                color: AppTheme.texto.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  isPaid ? paidByDisplayName : dueDateText, // Mostrar quién pagó si está pagada
                  style: TextStyle(
                    color: isPaid ? Colors.green : dueDateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.person,
                  size: 10,
                  color: AppTheme.texto.withOpacity(0.5),
                ),
                const SizedBox(width: 2),
                Text(
                  'Creada por: $userDisplayName',
                  style: TextStyle(
                    color: AppTheme.texto.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
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
                    color: AppTheme.texto,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (!isPaid && daysUntilDue <= 7)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dueDateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$daysUntilDue días',
                      style: TextStyle(
                        color: dueDateColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
              onPressed: () => _deleteBill(bill['id'], bill['title']),
              tooltip: 'Eliminar factura',
            ),
          ],
        ),
        onTap: () => _toggleBillStatus(bill['id'], isPaid),
        onLongPress: () => _deleteBill(bill['id'], bill['title']),
      ),
    );
  }
}