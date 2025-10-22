import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../core/app_theme.dart';

class AddBillPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String coupleId;

  const AddBillPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.coupleId,
  });

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _category = 'Servicios';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isPaid = false;
  
  // ✅ NUEVO: Campos para facturas recurrentes
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';

  final List<String> _billCategories = [
    'Servicios', 'Alquiler', 'Internet', 'Teléfono',
    'Impuestos', 'Seguro', 'Educación', 'Otros'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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

  Future<void> _submitBill() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      
      // ✅ NUEVO: Datos actualizados para facturas recurrentes
      final billData = {
        'amount': amount,
        'description': _descriptionController.text,
        'category': _category,
        'dueDate': _dueDate,
        'paid': _isPaid,
        // ✅ NUEVO: Campos de facturas recurrentes
        'isRecurring': _isRecurring,
        'recurrence': _recurrenceType,
        'originalDueDate': _dueDate,
        'nextDueDate': _dueDate,
        'paymentHistory': [],
        'totalPaid': 0,
        'status': _isPaid ? 'paid' : 'pending',
        'userId': widget.userId,
        'userName': widget.userName,
        'createdAt': DateTime.now(),
      };

      final result = await FirebaseService.addBill(
        billData, 
        widget.coupleId
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Factura ${_isRecurring ? 'recurrente ' : ''}agregada correctamente'),
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

  // ✅ NUEVO: Obtener texto de recurrencia
  String _getRecurrenceText(String recurrence) {
    switch (recurrence) {
      case 'monthly': return 'Mensual';
      case 'quarterly': return 'Trimestral';
      case 'yearly': return 'Anual';
      default: return 'Mensual';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text(
          'Agregar Factura',
          style: TextStyle(color: AppTheme.texto),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitBill,
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
              // Monto
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto*',
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
                          hintText: 'Descripción de la factura',
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
                        'Categoría*',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: _billCategories.map((category) {
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
              
              // ✅ NUEVO: Sección de Factura Recurrente
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Recurrencia',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Checkbox para factura recurrente
                      SwitchListTile(
                        title: Text(
                          'Factura Recurrente',
                          style: TextStyle(
                            color: AppTheme.texto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Se repite automáticamente cada periodo',
                          style: TextStyle(
                            color: AppTheme.texto.withOpacity(0.6),
                          ),
                        ),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                      
                      // Selector de recurrencia (solo si es recurrente)
                      if (_isRecurring) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Frecuencia de Repetición',
                          style: TextStyle(
                            color: AppTheme.texto,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _recurrenceType,
                          items: const [
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Mensual - Se repite cada mes'),
                            ),
                            DropdownMenuItem(
                              value: 'quarterly', 
                              child: Text('Trimestral - Se repite cada 3 meses'),
                            ),
                            DropdownMenuItem(
                              value: 'yearly',
                              child: Text('Anual - Se repite cada año'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _recurrenceType = value;
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cuando marques esta factura como pagada, se creará automáticamente una nueva para el próximo periodo.',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
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
                              const Spacer(),
                              if (_isRecurring)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getRecurrenceText(_recurrenceType),
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Esta será la fecha de vencimiento para cada periodo',
                          style: TextStyle(
                            color: AppTheme.texto.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Estado de pago
              Card(
                color: AppTheme.card1Fondo,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Pago',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(
                          _isPaid ? 'Pagada' : 'Pendiente',
                          style: TextStyle(color: AppTheme.texto),
                        ),
                        subtitle: _isRecurring && _isPaid
                            ? Text(
                                'Al marcar como pagada, se creará una nueva factura para el próximo periodo',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        value: _isPaid,
                        onChanged: (value) {
                          setState(() {
                            _isPaid = value;
                          });
                        },
                        activeColor: Colors.green,
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
                  onPressed: _submitBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecurring ? Colors.purple : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isRecurring 
                        ? 'Guardar Factura Recurrente' 
                        : 'Guardar Factura',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ✅ NUEVO: Información adicional
              if (_isRecurring)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.autorenew,
                            color: Colors.purple,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Factura Recurrente Configurada',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Se repite cada ${_getRecurrenceText(_recurrenceType).toLowerCase()}\n'
                        '• Próximo vencimiento: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}\n'
                        '• Se creará automáticamente una nueva factura al marcar como pagada',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}