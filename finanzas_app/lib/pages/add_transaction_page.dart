import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ AÑADIR ESTA IMPORTACIÓN
import '../services/firebase_service.dart';
import '../core/app_theme.dart';

class AddTransactionPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String coupleId;
  final String initialType;

  const AddTransactionPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.coupleId,
    this.initialType = 'expense',
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _type = 'expense';
  String _category = 'Comida';
  DateTime _selectedDate = DateTime.now();

  final List<String> _expenseCategories = [
    'Comida', 'Transporte', 'Entretenimiento', 'Salud', 
    'Hogar', 'Ropa', 'Educación', 'Otros'
  ];
  
  final List<String> _incomeCategories = [
    'Salario', 'Regalo', 'Inversión', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = widget.initialType == 'income' ? _incomeCategories.first : _expenseCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      
      // ✅ CORREGIDO: Incluir todos los campos necesarios
      final transactionData = {
        'amount': amount,
        'description': _descriptionController.text,
        'type': _type,
        'category': _category,
        'date': _selectedDate,
        'userId': widget.userId,
        'userName': widget.userName,
        'coupleId': widget.coupleId, // ✅ AÑADIDO: Campo essential
        'createdAt': FieldValue.serverTimestamp(), // ✅ CORREGIDO: Usar FieldValue
      };

      print('💾 Guardando transacción:'); // DEBUG
      print('   UserId: ${widget.userId}');
      print('   Type: $_type');
      print('   Amount: $amount');
      print('   Category: $_category');
      print('   CoupleId: ${widget.coupleId}');

      final result = await FirebaseService.addTransaction(
        transactionData, 
        widget.coupleId
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_type == 'income' ? 'Ingreso' : 'Gasto'} agregado correctamente'),
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
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: Text(
          _type == 'income' ? 'Agregar Ingreso' : 'Agregar Gasto',
          style: TextStyle(color: AppTheme.texto),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitTransaction,
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
              // Selector de tipo
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              'Gasto',
                              'expense',
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeButton(
                              'Ingreso',
                              'income',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Monto
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
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
                            return 'Ingresa un monto';
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
              
              // Descripción
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descripción',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Descripción de la transacción',
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
              
              // Categoría
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoría',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: (_type == 'income' 
                            ? _incomeCategories 
                            : _expenseCategories
                        ).map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                            });
                          }
                        },
                        decoration: InputDecoration(
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
              
              // Fecha
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
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
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
              
              const SizedBox(height: 32),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'income' ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Guardar ${_type == 'income' ? 'Ingreso' : 'Gasto'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String type, Color color) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _type = type;
          _category = type == 'income' ? _incomeCategories.first : _expenseCategories.first;
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: _type == type ? Colors.white : color,
        backgroundColor: _type == type ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}