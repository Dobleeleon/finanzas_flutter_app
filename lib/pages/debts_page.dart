import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/filter_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebtsPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String coupleId;
  final Map<String, dynamic> coupleData;

  const DebtsPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.coupleId,
    required this.coupleData,
  });

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _filteredDebts = [];
  bool _isLoading = true;
  
  // Filtros
  String _filterStatus = 'all';
  String _filterAssignedTo = 'all';
  double _minAmount = 0;
  double _maxAmount = 10000000;

  final Map<String, bool> _expandedDebts = {};

  // Variables para nombres de usuarios
  late String _user1Name;
  late String _user2Name;
  late String _currentUserRole;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadDebts();
  }

  void _initializeUserData() {
    if (widget.coupleData.isNotEmpty && widget.coupleData.containsKey('user1Name')) {
      _user1Name = widget.coupleData['user1Name'] ?? 'Usuario 1';
      _user2Name = widget.coupleData['user2Name'] ?? 'Usuario 2';
      
      final user1Id = widget.coupleData['user1Id'];
      _currentUserRole = (widget.userId == user1Id) ? 'user1' : 'user2';
    } else {
      _user1Name = widget.userName;
      _user2Name = 'Pareja';
      _currentUserRole = 'user1';
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  // ✅ CORREGIDO: Método de carga simplificado
  Future<void> _loadDebts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔍 Cargando deudas para coupleId: ${widget.coupleId}');
      
      final result = await FirebaseService.getDebts(widget.coupleId);
      
      if (result['success'] == true) {
        final debtsData = result['data'] as List<dynamic>;
        
        List<Map<String, dynamic>> debts = debtsData.map((debt) {
          final dueDate = debt['dueDate'] != null 
              ? (debt['dueDate'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 30));
              
          return {
            'id': debt['id'],
            'title': debt['description'] ?? 'Sin título',
            'originalAmount': (debt['amount'] ?? 0.0).toDouble(),
            'currentAmount': (debt['currentAmount'] ?? debt['amount'] ?? 0.0).toDouble(),
            'interestRate': (debt['interestRate'] ?? 0.0).toDouble(),
            'startDate': debt['createdAt'] != null 
                ? (debt['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            'dueDate': dueDate,
            'creditor': debt['creditor'] ?? 'Sin especificar',
            'assignedTo': debt['assignedTo'] ?? 'both',
            'status': debt['status'] ?? 'pending',
            'notes': debt['notes'] ?? '',
            'coupleId': debt['coupleId'] ?? widget.coupleId,
            'userId': debt['userId'] ?? widget.userId,
            'userName': debt['userName'] ?? widget.userName,
            'paymentHistory': debt['paymentHistory'] ?? [],
          };
        }).toList();

        // Ordenar: pendientes primero, luego por monto
        debts.sort((a, b) {
          final aIsPaid = (a['currentAmount'] ?? 0) <= 0 || a['status'] == 'paid';
          final bIsPaid = (b['currentAmount'] ?? 0) <= 0 || b['status'] == 'paid';
          
          if (aIsPaid != bIsPaid) {
            return aIsPaid ? 1 : -1;
          }
          return (b['currentAmount'] ?? 0).compareTo(a['currentAmount'] ?? 0);
        });

        // ✅ CRÍTICO: Actualizar AMBAS listas
        setState(() {
          _debts = debts;
          _filteredDebts = List.from(_debts); // ✅ Inicializar con todas las deudas
          _isLoading = false;
        });

        print('✅ Deudas cargadas: ${_debts.length}');
        print('✅ Deudas filtradas: ${_filteredDebts.length}');
        
      } else {
        throw Exception(result['error'] ?? 'Error al cargar deudas');
      }
    } catch (e) {
      print('💥 Error loading debts: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar deudas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_debts);

    if (_filterStatus != 'all') {
      filtered = filtered.where((d) => d['status'] == _filterStatus).toList();
    }

    if (_filterAssignedTo != 'all') {
      filtered = filtered.where((d) => d['assignedTo'] == _filterAssignedTo).toList();
    }

    filtered = filtered.where((d) {
      return d['currentAmount'] >= _minAmount && d['currentAmount'] <= _maxAmount;
    }).toList();

    setState(() {
      _filteredDebts = filtered;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getAssignedColor(String assignedTo) {
    switch (assignedTo) {
      case 'user1':
        return Colors.blue;
      case 'user2':
        return Colors.pink;
      case 'both':
        return Colors.purple;
      default:
        return AppTheme.botonesFondo;
    }
  }

  String _getAssignedText(String assignedTo) {
    switch (assignedTo) {
      case 'user1':
        return _user1Name;
      case 'user2':
        return _user2Name;
      case 'both':
        return 'Compartida';
      default:
        return assignedTo;
    }
  }

  String _getUserDisplayName(Map<String, dynamic> debt) {
    try {
      final currentUserId = widget.userId;
      final debtUserId = debt['userId'];
      final debtUserName = debt['userName'] ?? 'Usuario';
      
      if (debtUserId == currentUserId) {
        return 'Tú';
      } else {
        if (widget.coupleData.isNotEmpty) {
          final user1Id = widget.coupleData['user1Id'];
          if (debtUserId == user1Id) {
            return widget.coupleData['user1Name'] ?? 'Pareja';
          } else {
            return widget.coupleData['user2Name'] ?? 'Pareja';
          }
        }
        return debtUserName;
      }
    } catch (e) {
      return 'Usuario';
    }
  }

  void _resetFilters() {
    setState(() {
      _filterStatus = 'all';
      _filterAssignedTo = 'all';
      _minAmount = 0;
      _maxAmount = 10000000;
    });
    _applyFilters();
  }

  void _showFilterModal() {
    final assignedOptions = ['all', 'user1', 'user2', 'both'];
    final displayNames = {
      'all': 'Todos',
      'user1': _user1Name,
      'user2': _user2Name,
      'both': 'Compartida'
    };

    String selectedDisplayName = displayNames[_filterAssignedTo] ?? 'Todos';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        categories: assignedOptions.map((option) => displayNames[option]!).toList(),
        selectedCategory: selectedDisplayName,
        selectedDateFilter: 'all',
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        onCategoryChanged: (selected) {
          String internalValue = 'all';
          if (selected == _user1Name) {
            internalValue = 'user1';
          } else if (selected == _user2Name) {
            internalValue = 'user2';
          } else if (selected == 'Compartida') {
            internalValue = 'both';
          }
          
          setState(() {
            _filterAssignedTo = internalValue;
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
        resultsCount: _filteredDebts.length,
      ),
    );
  }

  // ✅ MEJORADO: Sistema de pagos con historial
 // ✅ MEJORADO: Modal de registro de pagos con interfaz profesional
Future<void> _registerPayment(String debtId, double currentAmount) async {
  final paymentController = TextEditingController();
  final noteController = TextEditingController();
  DateTime paymentDate = DateTime.now();
  TimeOfDay paymentTime = TimeOfDay.now();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.botonesFondo.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: AppTheme.botonesFondo,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Registrar Pago',
                  style: TextStyle(
                    color: AppTheme.texto,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la deuda actual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.card1Fondo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo actual:',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatCurrency(currentAmount),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de monto del pago
                Text(
                  'Monto del Pago*',
                  style: TextStyle(
                    color: AppTheme.texto,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ingresa el monto a pagar',
                    hintStyle: TextStyle(color: AppTheme.texto.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.attach_money, color: AppTheme.botonesFondo),
                    border: OutlineInputBorder(
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
                  style: TextStyle(color: AppTheme.texto),
                ),
                const SizedBox(height: 16),

                // Selector de fecha y hora
                Text(
                  'Fecha y Hora del Pago',
                  style: TextStyle(
                    color: AppTheme.texto,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.botonesFondo,
                                    onPrimary: AppTheme.botonesTexto,
                                    onSurface: AppTheme.texto,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.botonesFondo,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              paymentDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                paymentTime.hour,
                                paymentTime.minute,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card1Fondo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.texto.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(paymentDate),
                                style: TextStyle(
                                  color: AppTheme.texto,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.botonesFondo,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: paymentTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.botonesFondo,
                                    onPrimary: AppTheme.botonesTexto,
                                    onSurface: AppTheme.texto,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setState(() {
                              paymentTime = pickedTime;
                              paymentDate = DateTime(
                                paymentDate.year,
                                paymentDate.month,
                                paymentDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card1Fondo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.texto.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${paymentTime.hour.toString().padLeft(2, '0')}:${paymentTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: AppTheme.texto,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: AppTheme.botonesFondo,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo de notas
                Text(
                  'Notas (Opcional)',
                  style: TextStyle(
                    color: AppTheme.texto,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Pago parcial, transferencia, etc.',
                    hintStyle: TextStyle(color: AppTheme.texto.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.note, color: AppTheme.botonesFondo),
                    border: OutlineInputBorder(
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
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.texto),
                ),
                const SizedBox(height: 8),

                // Información de quién registra el pago
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.botonesFondo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppTheme.botonesFondo,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registrado por: ${widget.userName}',
                          style: TextStyle(
                            color: AppTheme.texto.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Botón Cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.texto.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancelar'),
            ),

            // Botón Registrar Pago
            ElevatedButton(
              onPressed: () async {
                final paymentAmount = double.tryParse(paymentController.text) ?? 0;
                if (paymentAmount > 0 && paymentAmount <= currentAmount) {
                  try {
                    final newAmount = currentAmount - paymentAmount;
                    final isPaid = newAmount <= 0;
                    
                    // ✅ MEJORADO: Registrar pago con fecha específica
                    final paymentRecord = {
                      'paymentDate': Timestamp.fromDate(paymentDate), // ✅ Fecha específica del pago
                      'amount': paymentAmount,
                      'paidBy': widget.userId,
                      'paidByName': widget.userName,
                      'notes': noteController.text,
                      'remainingBalance': newAmount,
                    };

                    final updates = {
                      'currentAmount': newAmount,
                      'status': isPaid ? 'paid' : 'pending',
                      'updatedAt': FieldValue.serverTimestamp(),
                      'paymentHistory': FieldValue.arrayUnion([paymentRecord]),
                    };

                    final result = await FirebaseService.updateDebt(debtId, updates);
                    
                    if (result['success'] == true) {
                      _loadDebts();
                      Navigator.pop(context);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Pago de ${_formatCurrency(paymentAmount)} registrado${isPaid ? ' - ¡Deuda pagada!' : ''}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      throw Exception(result['error']);
                    }
                  } catch (e) {
                    print('❌ Error al registrar pago: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error al registrar pago: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Monto inválido. Debe ser mayor a 0 y menor o igual a ${_formatCurrency(currentAmount)}'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.botonesFondo,
                foregroundColor: AppTheme.botonesTexto,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Registrar Pago'),
            ),
          ],
        );
      },
    ),
  );
}

  Future<void> _applyInterest(String debtId, String debtTitle, double currentAmount, double interestRate) async {
    if (interestRate <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Esta deuda no tiene tasa de interés configurada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aplicar Interés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Aplicar interés mensual a "$debtTitle"?'),
            const SizedBox(height: 8),
            Text(
              'Interés: $interestRate% = ${_formatCurrency(currentAmount * (interestRate / 100))}',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuevo total: ${_formatCurrency(currentAmount + (currentAmount * (interestRate / 100)))}',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
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
            onPressed: () async {
              try {
                final interestAmount = currentAmount * (interestRate / 100);
                final newAmount = currentAmount + interestAmount;
                
                final updates = {
                  'currentAmount': newAmount,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                final result = await FirebaseService.updateDebt(debtId, updates);
                
                if (result['success'] == true) {
                  _loadDebts();
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Interés de ${_formatCurrency(interestAmount)} aplicado'),
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
                    SnackBar(
                      content: Text('Error al aplicar interés: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar Interés'),
          ),
        ],
      ),
    );
  }

  // ... (los métodos _showAddDebtDialog y _deleteDebt se mantienen igual)

  Future<void> _showAddDebtDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final interestController = TextEditingController(text: '0');
    final creditorController = TextEditingController();
    final notesController = TextEditingController();

    String assignedTo = 'both';
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nueva Deuda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la deuda*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto total*',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: interestController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés mensual (%)',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: creditorController,
                    decoration: const InputDecoration(
                      labelText: 'Acreedor*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: assignedTo,
                    decoration: const InputDecoration(
                      labelText: 'Asignada a',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'both', child: const Text('Compartida')),
                      DropdownMenuItem(value: 'user1', child: Text(_user1Name)),
                      DropdownMenuItem(value: 'user2', child: Text(_user2Name)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        assignedTo = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dueDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(dueDate)),
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
                  final interestRate = double.tryParse(interestController.text) ?? 0;

                  if (titleController.text.isEmpty || amount <= 0 || creditorController.text.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor completa los campos obligatorios (*)'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    final debtData = {
                      'description': titleController.text,
                      'amount': amount,
                      'currentAmount': amount,
                      'interestRate': interestRate,
                      'creditor': creditorController.text,
                      'assignedTo': assignedTo,
                      'status': 'pending',
                      'notes': notesController.text,
                      'dueDate': dueDate,
                      'coupleId': widget.coupleId,
                      'userId': widget.userId,
                      'userName': widget.userName,
                      'createdAt': FieldValue.serverTimestamp(),
                      'paymentHistory': [],
                    };

                    final result = await FirebaseService.addDebt(debtData, widget.coupleId);
                    
                    if (result['success'] == true) {
                      _loadDebts();
                      Navigator.pop(context);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deuda "${titleController.text}" agregada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      throw Exception(result['error']);
                    }
                  } catch (e) {
                    print('❌ Error al agregar deuda: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar deuda: $e'),
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
                child: const Text('Agregar Deuda'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteDebt(String debtId, String debtTitle) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deuda'),
        content: Text('¿Estás seguro de que quieres eliminar la deuda "$debtTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await FirebaseService.deleteDebt(debtId);
                
                if (result['success'] == true) {
                  _loadDebts();
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deuda "$debtTitle" eliminada'),
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
                    SnackBar(
                      content: Text('Error al eliminar deuda: $e'),
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
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final activeDebts = _filteredDebts.where((debt) => debt['currentAmount'] > 0);
    final totalDebt = activeDebts.fold(0.0, (sum, debt) => sum + debt['currentAmount']);
    final monthlyInterest = activeDebts.fold(0.0, (sum, debt) => sum + (debt['currentAmount'] * (debt['interestRate'] / 100)));

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
                  Column(
                    children: [
                      Text(
                        'Deuda Total',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalDebt),
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Interés Mensual',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatCurrency(monthlyInterest),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.texto.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text(
                '${activeDebts.length} deuda${activeDebts.length != 1 ? 's' : ''} activa${activeDebts.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.credit_score,
                size: 64,
                color: AppTheme.texto.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay deudas',
                style: TextStyle(
                  color: AppTheme.texto.withOpacity(0.5),
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _filterStatus != 'all' || _filterAssignedTo != 'all' 
                    ? 'Prueba ajustar los filtros'
                    : 'Agrega tu primera deuda usando el botón +',
                style: TextStyle(
                  color: AppTheme.texto.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_filterStatus != 'all' || _filterAssignedTo != 'all')
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
        ),
      ),
    );
  }

  // ✅ MEJORADO: Widget de deuda con historial de pagos
  Widget _buildDebtItem(Map<String, dynamic> debt) {
    final currentAmount = debt['currentAmount'] ?? 0.0;
    final originalAmount = debt['originalAmount'] ?? 0.0;
    final interestRate = debt['interestRate'] ?? 0.0;
    final assignedTo = debt['assignedTo'] ?? 'both';
    final userDisplayName = _getUserDisplayName(debt);
    final paymentHistory = debt['paymentHistory'] ?? [];
    
    final monthsPassed = ((DateTime.now().difference(debt['startDate']).inDays) / 30).ceil();
    final accumulatedInterest = currentAmount - originalAmount;
    final nextInterest = currentAmount * (interestRate / 100);
    final isPaid = currentAmount <= 0 || debt['status'] == 'paid';

    final isExpanded = _expandedDebts[debt['id']] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.card1Fondo,
      child: ExpansionTile(
        key: Key(debt['id']),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedDebts[debt['id']] = expanded;
          });
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.credit_card,
            color: isPaid ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt['title'],
                    style: TextStyle(
                      color: AppTheme.texto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
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
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(currentAmount),
                  style: TextStyle(
                    color: isPaid ? Colors.green : AppTheme.texto,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getAssignedColor(assignedTo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getAssignedText(assignedTo),
                    style: TextStyle(
                      color: _getAssignedColor(assignedTo),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          '${debt['creditor']} • $interestRate% interés',
          style: TextStyle(
            color: AppTheme.texto.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: Colors.red.withOpacity(0.6),
          onPressed: () => _deleteDebt(debt['id'], debt['title']),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información detallada
                _buildDebtDetailItem('Monto Original', _formatCurrency(originalAmount)),
                _buildDebtDetailItem('Interés Acumulado', _formatCurrency(accumulatedInterest)),
                _buildDebtDetailItem('Meses Transcurridos', '$monthsPassed meses'),
                if (interestRate > 0) _buildDebtDetailItem('Próximo Interés', _formatCurrency(nextInterest)),
                _buildDebtDetailItem('Fecha Inicio', _formatDate(debt['startDate'])),
                _buildDebtDetailItem('Creada por', userDisplayName),
                
                if (debt['notes'] != null && debt['notes'].isNotEmpty)
                  _buildDebtDetailItem('Notas', debt['notes']),
                
                // ✅ NUEVO: Historial de pagos
                if (paymentHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Historial de Pagos:',
                    style: TextStyle(
                      color: AppTheme.texto,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...paymentHistory.reversed.map((payment) {
                    final paymentDate = payment['paymentDate'] != null 
                        ? (payment['paymentDate'] as Timestamp).toDate()
                        : DateTime.now();
                    final paidByName = payment['paidByName'] ?? 'Usuario';
                    final amount = (payment['amount'] ?? 0.0).toDouble();
                    final notes = payment['notes'] ?? '';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pagado por: $paidByName',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatCurrency(amount),
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Fecha: ${_formatDateTime(paymentDate)}',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                          if (notes.isNotEmpty)
                            Text(
                              'Nota: $notes',
                              style: TextStyle(
                                color: AppTheme.texto.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                
                const SizedBox(height: 16),
                
                // Botones de acción
                if (!isPaid) Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _registerPayment(debt['id'], currentAmount),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Registrar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (interestRate > 0) Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyInterest(debt['id'], debt['title'], currentAmount, interestRate),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: const Text('Aplicar Interés'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (isPaid) Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Deuda completamente pagada',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.texto,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
        title: Text(
          'Gestión de Deudas',
          style: TextStyle(
            color: AppTheme.texto,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.card1Fondo,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            color: AppTheme.botonesFondo,
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppTheme.botonesFondo,
            onPressed: _loadDebts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.botonesFondo),
                  SizedBox(height: 16),
                  Text('Cargando deudas...', style: TextStyle(color: AppTheme.texto)),
                ],
              ),
            )
          : Column(
              children: [
                _buildQuickFilters(),
                _buildSummary(),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredDebts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDebts,
                          child: ListView.builder(
                            itemCount: _filteredDebts.length,
                            itemBuilder: (context, index) {
                              final debt = _filteredDebts[index];
                              return _buildDebtItem(debt);
                            },
                          ),
                        ),
                ),
              ],
            ),

    );
  }
}