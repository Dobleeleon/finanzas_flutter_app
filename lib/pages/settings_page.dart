import 'package:flutter/material.dart';
import 'package:finanzas_app/services/firebase_service.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  final double monthlyIncome;
  final Function(double) onIncomeUpdated;
  final Function onSignOut;

  const SettingsPage({
    Key? key,
    required this.userName,
    required this.monthlyIncome,
    required this.onIncomeUpdated,
    required this.onSignOut,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _incomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _incomeController.text = widget.monthlyIncome.toStringAsFixed(2);
  }

  void _showUpdateIncomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar Ingreso Mensual'),
        content: TextField(
          controller: _incomeController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Ingreso Mensual',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newIncome = double.tryParse(_incomeController.text) ?? 0.0;
              widget.onIncomeUpdated(newIncome);
              Navigator.of(context).pop();
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text('Nombre'),
                      subtitle: Text(widget.userName),
                    ),
                    ListTile(
                      leading: Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Ingreso Mensual'),
                      subtitle: Text('\$${widget.monthlyIncome.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: _showUpdateIncomeDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text('Acerca de'),
                    subtitle: Text('Finanzas App v1.0.0'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Finanzas App',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(Icons.account_balance_wallet, color: Colors.blue),
                        children: [
                          Text('Una aplicación para controlar tus gastos e ingresos.'),
                        ],
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                    onTap: _showSignOutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}