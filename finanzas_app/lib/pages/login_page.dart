// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/preferences_service.dart';
import 'main_wrapper.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkAutoLogin();
  }

  void _loadSavedCredentials() async {
    try {
      final credentials = await PreferencesService.getSavedCredentials();
      
      setState(() {
        _rememberMe = credentials['rememberMe'] ?? false;
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
      });
    } catch (e) {
      // Silenciar error
    }
  }

  void _checkAutoLogin() async {
    try {
      final isLoggedIn = await PreferencesService.isLoggedIn();
      final credentials = await PreferencesService.getSavedCredentials();
      
      if (isLoggedIn && _rememberMe && credentials['email']!.isNotEmpty) {
        _autoLogin();
      }
    } catch (e) {
      // Silenciar error
    }
  }

  void _autoLogin() async {
    try {
      final credentials = await PreferencesService.getSavedCredentials();
      final email = credentials['email']!;
      final password = credentials['password']!;

      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final result = await FirebaseService.loginUser(email, password);

        if (result['success'] == true) {
          await _navigateToMainWrapper(result['data'] as String);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveCredentials() async {
    try {
      await PreferencesService.saveCredentials(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
        _rememberMe,
      );
    } catch (e) {
      // Silenciar error
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _saveCredentials();

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final result = await FirebaseService.loginUser(email, password);

      if (result['success'] == true) {
        await PreferencesService.setLoggedIn(true);
        await _navigateToMainWrapper(result['data'] as String);
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error al iniciar sesión';
          _isLoading = false;
        });
        await PreferencesService.setLoggedIn(false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
      await PreferencesService.setLoggedIn(false);
    }
  }

  Future<void> _navigateToMainWrapper(String userId) async {
    try {
      final userProfile = await FirebaseService.getUserProfile(userId);
      
      if (userProfile['success'] == true) {
        final userData = userProfile['data'] as Map<String, dynamic>;
        final userName = userData['name'] ?? 'Usuario';
        final coupleId = userData['coupleId'] ?? '';
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainWrapper(
                userName: userName,
                userId: userId,
                coupleId: coupleId,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Error al cargar el perfil del usuario';
          _isLoading = false;
        });
        await PreferencesService.setLoggedIn(false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el perfil del usuario';
        _isLoading = false;
      });
      await PreferencesService.setLoggedIn(false);
    }
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: isSmallScreen ? 20.0 : 40.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
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
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Finanzas Pareja',
                            style: TextStyle(
                              color: AppTheme.texto,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestiona tus finanzas\nde manera inteligente',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.6),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

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
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.texto.withOpacity(0.5),
                                ),
                              ),
                              validator: _validateEmail,
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: TextStyle(
                                  color: AppTheme.texto.withOpacity(0.6),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.texto.withOpacity(0.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.texto.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value!;
                                          });
                                          _saveCredentials();
                                        },
                                        activeColor: AppTheme.botonesFondo,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recordar',
                                      style: TextStyle(
                                        color: AppTheme.texto.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),

                                TextButton(
                                  onPressed: _isLoading ? null : _goToForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: AppTheme.botonesFondo,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.botonesFondo,
                                  foregroundColor: AppTheme.botonesTexto,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: AppTheme.texto.withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToRegister,
                            child: Text(
                              'Regístrate',
                              style: TextStyle(
                                color: AppTheme.botonesFondo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}