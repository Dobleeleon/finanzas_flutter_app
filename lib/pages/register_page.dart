// lib/pages/register_page.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _partnerEmailController = TextEditingController(); // Nuevo campo para pareja
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _hasPartner = false; // Para controlar si muestra el campo de pareja
  
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos y condiciones';
      });
      return;
    }

    // Validar que si tiene pareja, ingrese el email
    if (_hasPartner && _partnerEmailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa el email de tu pareja';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final partnerEmail = _hasPartner ? _partnerEmailController.text.trim().toLowerCase() : null;

      // 1. Registrar el usuario principal
      final result = await FirebaseService.registerUser(email, password, name);

      if (result['success'] == true) {
        final userId = result['data'] as String;
        
        // 2. Si tiene pareja, vincularla
        if (_hasPartner && partnerEmail != null && partnerEmail.isNotEmpty) {
          final coupleResult = await FirebaseService.createCouple(userId, partnerEmail);
          
          if (coupleResult['success'] == true) {
            // Registro y vinculación exitosos
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Registro exitoso. Pareja vinculada.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Registro exitoso pero falló la vinculación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Registro exitoso. Pero: ${coupleResult['error']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Registro exitoso sin pareja
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro exitoso.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Navegar al login después de un breve delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error al registrar usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validatePartnerEmail(String? value) {
    if (_hasPartner && (value == null || value.isEmpty)) {
      return 'Por favor ingresa el email de tu pareja';
    }
    if (_hasPartner && value != null && value.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Ingresa un email válido para tu pareja';
      }
      if (value == _emailController.text.trim().toLowerCase()) {
        return 'No puedes usar tu propio email';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.texto, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: isSmallScreen ? 10.0 : 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.botonesFondo,
                                  const Color(0xFFFFB74D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.botonesFondo.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_add_alt_1,
                              size: 35,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              color: AppTheme.texto,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Comienza a gestionar tus finanzas',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 25 : 35),

                      // Mensaje de error
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage != null) const SizedBox(height: 16),

                      // Formulario de Registro
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Nombre
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre completo',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.botonesFondo,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.fondo.withOpacity(0.4),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppTheme.texto.withOpacity(0.5),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.texto,
                                fontSize: 15,
                              ),
                              validator: _validateName,
                            ),

                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Tu email',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.botonesFondo,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.fondo.withOpacity(0.4),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.texto.withOpacity(0.5),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.texto,
                                fontSize: 15,
                              ),
                              validator: _validateEmail,
                            ),

                            const SizedBox(height: 16),

                            // Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.botonesFondo,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.fondo.withOpacity(0.4),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.texto.withOpacity(0.5),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.texto.withOpacity(0.5),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.texto,
                                fontSize: 15,
                              ),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 16),

                            // Confirmar Contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.botonesFondo,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.fondo.withOpacity(0.4),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.texto.withOpacity(0.5),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.texto.withOpacity(0.5),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.texto,
                                fontSize: 15,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor confirma tu contraseña';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Opción de pareja
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.fondo.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.botonesFondo.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: AppTheme.botonesFondo,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '¿Tienes pareja?',
                                        style: TextStyle(
                                          color: AppTheme.texto,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: _hasPartner,
                                        onChanged: (value) {
                                          setState(() {
                                            _hasPartner = value;
                                          });
                                        },
                                        activeColor: AppTheme.botonesFondo,
                                      ),
                                    ],
                                  ),
                                  
                                  if (_hasPartner) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _partnerEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Email de tu pareja',
                                        labelStyle: TextStyle(
                                          color: AppTheme.texto.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppTheme.botonesFondo,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: AppTheme.texto.withOpacity(0.5),
                                          size: 20,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        hintText: 'pareja@email.com',
                                      ),
                                      style: TextStyle(
                                        color: AppTheme.texto,
                                        fontSize: 15,
                                      ),
                                      validator: _validatePartnerEmail,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tu pareja debe estar registrada con este email',
                                      style: TextStyle(
                                        color: AppTheme.texto.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Términos y Condiciones
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value!;
                                      });
                                    },
                                    activeColor: AppTheme.botonesFondo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: AppTheme.texto.withOpacity(0.7),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Acepto los '),
                                        TextSpan(
                                          text: 'términos y condiciones',
                                          style: TextStyle(
                                            color: AppTheme.botonesFondo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(text: ' y la '),
                                        TextSpan(
                                          text: 'política de privacidad',
                                          style: TextStyle(
                                            color: AppTheme.botonesFondo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Botón de Registro
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.botonesFondo,
                                  foregroundColor: AppTheme.botonesTexto,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  shadowColor: AppTheme.botonesFondo.withOpacity(0.3),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Crear Cuenta',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Enlace a Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToLogin,
                            child: Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: AppTheme.botonesFondo,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Espacio flexible
                      if (!isSmallScreen) const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _partnerEmailController.dispose();
    super.dispose();
  }
}