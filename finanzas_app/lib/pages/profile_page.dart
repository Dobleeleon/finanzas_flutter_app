// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String coupleId;
  final Map<String, dynamic> coupleData;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.coupleId,
    required this.coupleData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _incomeController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseService.getUserProfile(widget.userId);
      
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _incomeController.text = (userData['monthlyIncome'] ?? 0.0).toString();
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error al cargar el perfil';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateProfile() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'monthlyIncome': double.tryParse(_incomeController.text) ?? 0.0,
        'updatedAt': DateTime.now(),
      };

      final result = await FirebaseService.updateUserProfile(widget.userId, updates);

      if (result['success'] == true) {
        setState(() {
          _successMessage = 'Perfil actualizado correctamente';
          _isEditing = false;
        });
        
        // Ocultar mensaje después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = '';
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error al actualizar el perfil';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'El nombre es obligatorio';
      });
      return false;
    }

    final income = double.tryParse(_incomeController.text);
    if (income == null || income < 0) {
      setState(() {
        _errorMessage = 'Ingresa un ingreso mensual válido';
      });
      return false;
    }

    return true;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _errorMessage = '';
      _successMessage = '';
    });
    _loadUserProfile(); // Recargar datos originales
  }

  // Función para formatear moneda en COP
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )} COP';
  }

  // Obtener nombre de la pareja
  String _getPartnerName() {
    if (widget.coupleData.isEmpty) return 'Sin pareja vinculada';
    
    final user1Id = widget.coupleData['user1Id'];
    final user2Id = widget.coupleData['user2Id'];
    
    // Determinar cuál es el partner
    if (user1Id == widget.userId) {
      return widget.coupleData['user2Name'] ?? 'Pareja';
    } else {
      return widget.coupleData['user1Name'] ?? 'Pareja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.card1Fondo,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.texto),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.botonesFondo),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.botonesFondo,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar y información básica
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.botonesFondo,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Usuario',
                    style: TextStyle(
                      color: AppTheme.texto,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userEmail,
                    style: TextStyle(
                      color: AppTheme.texto.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  
                  // Información de pareja
                  if (widget.coupleId.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.botonesFondo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: AppTheme.botonesFondo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pareja: ${_getPartnerName()}',
                            style: TextStyle(
                              color: AppTheme.botonesFondo,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),

                  // Mensajes de error/éxito
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_successMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage,
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Formulario de perfil
                  Card(
                    color: AppTheme.card1Fondo,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            style: TextStyle(color: AppTheme.texto),
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              labelStyle: TextStyle(color: AppTheme.texto.withOpacity(0.6)),
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
                              prefixIcon: Icon(Icons.person, color: AppTheme.texto.withOpacity(0.5)),
                              filled: true,
                              fillColor: AppTheme.fondo,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email (solo lectura)
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            style: TextStyle(color: AppTheme.texto.withOpacity(0.6)),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: AppTheme.texto.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                              ),
                              prefixIcon: Icon(Icons.email, color: AppTheme.texto.withOpacity(0.5)),
                              filled: true,
                              fillColor: AppTheme.fondo.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ingreso mensual
                          TextFormField(
                            controller: _incomeController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.texto),
                            decoration: InputDecoration(
                              labelText: 'Ingreso mensual (COP)',
                              labelStyle: TextStyle(color: AppTheme.texto.withOpacity(0.6)),
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
                              prefixIcon: Icon(Icons.attach_money, color: AppTheme.texto.withOpacity(0.5)),
                              filled: true,
                              fillColor: AppTheme.fondo,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botones de acción
                          if (_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.texto,
                                      side: BorderSide(color: AppTheme.texto.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.botonesFondo,
                                      foregroundColor: AppTheme.botonesTexto,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Guardar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _incomeController.dispose();
    super.dispose();
  }
}