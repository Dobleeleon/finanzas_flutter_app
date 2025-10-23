import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../core/app_theme.dart';

class AddDebtPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String coupleId;

  const AddDebtPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.coupleId,
  });

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _creditorController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _assignedTo = 'both';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  
  // ✅ NUEVO: Campos para deudas recurrentes
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';
  
  // ✅ NUEVO: Campos para plan de pagos
  int _numberOfMonths = 12;
  String _paymentType = 'fixed';
  List<Map<String, dynamic>> _paymentPlan = [];

  @override
  void initState() {
    super.initState();
    _calculatePaymentPlan();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _descriptionController.dispose();
    _creditorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // ✅ NUEVO: Calcular plan de pagos
  void _calculatePaymentPlan() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interestRate = double.tryParse(_interestController.text) ?? 0;
    
    if (amount > 0 && _numberOfMonths > 0) {
      final result = FirebaseService.calculatePaymentPlan(
        amount,
        interestRate,
        _numberOfMonths,
        _paymentType
      );
      
      if (result['success'] == true) {
        setState(() {
          _paymentPlan = (result['data']['payments'] as List<dynamic>).cast<Map<String, dynamic>>();
        });
      }
    }
  }

  // ✅ NUEVO: Obtener texto de recurrencia
  String _getRecurrenceText(String recurrence) {
    switch (recurrence) {
      case 'monthly': return 'Mensual';
      case 'quarterly': return 'Trimestral';
      case 'yearly': return 'Anual';
      default: return 'Mensual';
    }
  }

  Future<void> _submitDebt() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final interestRate = double.tryParse(_interestController.text) ?? 0;
      
      // ✅ NUEVO: Datos actualizados para deudas con plan de pagos
      final debtData = {
        'amount': amount,
        'currentAmount': amount, // ✅ Saldo actual que se irá reduciendo
        'interestRate': interestRate,
        'description': _descriptionController.text,
        'creditor': _creditorController.text.isEmpty ? 'Sin especificar' : _creditorController.text,
        'assignedTo': _assignedTo,
        'dueDate': _dueDate,
        // ✅ NUEVO: Campos de deudas recurrentes
        'isRecurring': _isRecurring,
        'recurrence': _recurrenceType,
        'originalDueDate': _dueDate,
        'nextDueDate': _dueDate,
        // ✅ NUEVO: Campos de seguimiento
        'paymentHistory': [],
        'interestHistory': [],
        'totalPaid': 0,
        'totalInterest': 0,
        'status': 'pending',
        'notes': _notesController.text,
        // ✅ NUEVO: Plan de pagos
        'paymentPlan': {
          'type': _paymentType,
          'numberOfMonths': _numberOfMonths,
          'projectedPayments': _paymentPlan,
        },
        'userId': widget.userId,
        'userName': widget.userName,
        'createdAt': DateTime.now(),
      };

      final result = await FirebaseService.addDebt(
        debtData, 
        widget.coupleId
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deuda ${_isRecurring ? 'recurrente ' : ''}agregada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interestRate = double.tryParse(_interestController.text) ?? 0;
    final totalWithInterest = amount + (amount * (interestRate / 100));

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text(
          'Agregar Deuda',
          style: TextStyle(color: AppTheme.texto),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitDebt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monto Total
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto Total de la Deuda*',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculatePaymentPlan(),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.fondo,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el monto total';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tasa de Interés
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasa de Interés Mensual (%)',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _interestController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculatePaymentPlan(),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: '%',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.fondo,
                        ),
                      ),
                      if (interestRate > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Interés mensual: \$${(amount * (interestRate / 100)).toStringAsFixed(0)} COP',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Descripción
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descripción*',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Descripción de la deuda',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.fondo,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una descripción';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Acreedor
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acreedor',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _creditorController,
                        decoration: InputDecoration(
                          hintText: 'Banco, persona, entidad...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.fondo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ✅ NUEVO: Plan de Pagos
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan de Pagos',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Tipo de pago
                      DropdownButtonFormField<String>(
                        value: _paymentType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Plan de Pagos',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('Cuotas Fijas'),
                          ),
                          DropdownMenuItem(
                            value: 'minimum', 
                            child: Text('Pago Mínimo'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _paymentType = value;
                              _calculatePaymentPlan();
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Número de meses
                      TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: _numberOfMonths.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Número de Meses para Pagar',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final months = int.tryParse(value) ?? 12;
                          if (months > 0) {
                            setState(() {
                              _numberOfMonths = months;
                              _calculatePaymentPlan();
                            });
                          }
                        },
                      ),
                      
                      // Resumen del plan
                      if (_paymentPlan.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen del Plan:',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total a Pagar: \$${totalWithInterest.toStringAsFixed(0)} COP\n'
                                'Interés Total: \$${(totalWithInterest - amount).toStringAsFixed(0)} COP\n'
                                'Cuota ${_paymentType == 'fixed' ? 'Fija' : 'Mínima'}: \$${_paymentPlan.first['monthlyPayment']?.toStringAsFixed(0) ?? '0'} COP/mes',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ✅ NUEVO: Deuda Recurrente
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deuda Recurrente',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(
                          'Es una deuda recurrente',
                          style: TextStyle(color: AppTheme.texto),
                        ),
                        subtitle: Text(
                          'Se repite automáticamente cada periodo',
                          style: TextStyle(
                            color: AppTheme.texto.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: Colors.purple,
                      ),
                      
                      if (_isRecurring) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _recurrenceType,
                          decoration: const InputDecoration(
                            labelText: 'Frecuencia de Repetición',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                            DropdownMenuItem(value: 'quarterly', child: Text('Trimestral')),
                            DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _recurrenceType = value;
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Fecha de vencimiento
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de Vencimiento*',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDueDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.fondo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.texto,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                style: TextStyle(
                                  color: AppTheme.texto,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notas
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas (opcional)',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Notas adicionales sobre la deuda...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.fondo,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              // ✅ NUEVO: Vista Previa del Plan de Pagos
              if (_paymentPlan.isNotEmpty && amount > 0) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.card1Fondo,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vista Previa del Plan de Pagos',
                          style: TextStyle(
                            color: AppTheme.texto,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _paymentPlan.length,
                            itemBuilder: (context, index) {
                              final payment = _paymentPlan[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.fondo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Mes ${payment['month']}',
                                        style: TextStyle(
                                          color: AppTheme.texto,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${payment['monthlyPayment']?.toStringAsFixed(0) ?? '0'}',
                                            style: TextStyle(
                                              color: AppTheme.texto,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Saldo: \$${payment['remainingBalance']?.toStringAsFixed(0) ?? '0'}',
                                            style: TextStyle(
                                              color: AppTheme.texto.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecurring ? Colors.purple : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isRecurring 
                        ? 'Guardar Deuda Recurrente' 
                        : 'Guardar Deuda',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}