import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/preferences_service.dart';
import 'dashboard_page.dart';
import 'transactions_page.dart';
import 'bills_page.dart';
import 'debts_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'add_transaction_page.dart';
import 'add_bill_page.dart';
import 'add_debt_page.dart';

class MainWrapper extends StatefulWidget {
  final String userName;
  final String userId;
  final String coupleId;

  const MainWrapper({
    super.key,
    required this.userName,
    required this.userId,
    required this.coupleId,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  String _userEmail = '';
  Map<String, dynamic> _coupleData = {};
  bool _isLoadingCoupleData = true;

  // Lista de páginas disponibles - INICIALIZADA COMO VACÍA
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _loadCoupleData();
  }

  void _loadUserEmail() async {
    final user = await FirebaseService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
      });
    }
  }

  void _loadCoupleData() async {
    try {
      if (widget.coupleId.isNotEmpty) {
        final result = await FirebaseService.getCouple(widget.coupleId);
        if (result['success'] == true) {
          setState(() {
            _coupleData = result['data'];
            _isLoadingCoupleData = false;
          });
        } else {
          setState(() {
            _isLoadingCoupleData = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCoupleData = false;
        });
      }
    } catch (e) {
      print('Error loading couple data: $e');
      setState(() {
        _isLoadingCoupleData = false;
      });
    }
  }

  void _initializePages() {
    _pages = [
      DashboardPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      ),
      TransactionsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      ),
      BillsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      ),
      DebtsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      ),
    ];
    
    print('🔄 Páginas inicializadas con coupleId: ${widget.coupleId}');
    print('📊 Datos de pareja: ${_coupleData.isNotEmpty ? "CARGADOS" : "VACÍOS"}');
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userId: widget.userId,
          userName: widget.userName,
          userEmail: _userEmail,
          coupleId: widget.coupleId,
          coupleData: _coupleData,
        ),
      ),
    );
  }

  void _signOut() async {
    await PreferencesService.setLoggedIn(false);

    final result = await FirebaseService.signOut();
    
    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del menú
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.botonesFondo,
                  child: Text(
                    widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppTheme.botonesTexto,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const Divider(),
              
              // Opción de perfil
              ListTile(
                leading: Icon(Icons.person, color: AppTheme.botonesFondo),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToProfile();
                },
              ),
              
              // Opción de cierre de sesión
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade600),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation();
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDataModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 360;
        final maxModalHeight = screenHeight * 0.8;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Espacio para cerrar arrastrando
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Contenido del modal con altura limitada
              Container(
                constraints: BoxConstraints(
                  maxHeight: maxModalHeight,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card1Fondo,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        'Agregar Nuevo',
                        style: TextStyle(
                          color: AppTheme.texto,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Opciones en lista vertical (mejor para móviles)
                      Column(
                        children: [
                          // Ingreso
                          _buildOptionItem(
                            icon: Icons.arrow_circle_down_rounded,
                            title: 'Ingreso',
                            subtitle: 'Agregar dinero entrante',
                            color: Colors.green,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToAddTransaction('income');
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Gasto
                          _buildOptionItem(
                            icon: Icons.arrow_circle_up_rounded,
                            title: 'Gasto',
                            subtitle: 'Registrar gasto',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToAddTransaction('expense');
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Factura
                          _buildOptionItem(
                            icon: Icons.receipt_long_rounded,
                            title: 'Factura',
                            subtitle: 'Agregar factura pendiente',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToAddBill();
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Deuda
                          _buildOptionItem(
                            icon: Icons.account_balance_rounded,
                            title: 'Deuda',
                            subtitle: 'Registrar deuda o préstamo',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToAddDebt();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Botón de cancelar
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget para cada opción en lista vertical
  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.texto.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.texto,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.texto.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.texto.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAVEGACIÓN A LAS PÁGINAS REALES
  void _navigateToAddTransaction(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          coupleId: widget.coupleId,
          userId: widget.userId,
          userName: widget.userName,
          initialType: type,
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese
      _refreshCurrentPage();
    });
  }

  void _navigateToAddBill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBillPage(
          coupleId: widget.coupleId,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese
      _refreshCurrentPage();
    });
  }

  void _navigateToAddDebt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtPage(
          coupleId: widget.coupleId,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese
      _refreshCurrentPage();
    });
  }

  void _refreshCurrentPage() {
    // Recargar la página actual después de agregar datos
    if (_pages.isNotEmpty && _pages[_currentIndex] is StatefulWidget) {
      setState(() {
        // Esto fuerza a recargar la página actual
        final currentPage = _pages[_currentIndex];
        _pages[_currentIndex] = _recreatePage(currentPage);
      });
    }
  }

  Widget _recreatePage(Widget page) {
    if (page is DashboardPage) {
      return DashboardPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      );
    } else if (page is TransactionsPage) {
      return TransactionsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      );
    } else if (page is BillsPage) {
      return BillsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      );
    } else if (page is DebtsPage) {
      return DebtsPage(
        userName: widget.userName,
        userId: widget.userId,
        coupleId: widget.coupleId,
        coupleData: _coupleData,
      );
    }
    return page;
  }

  // ✅ MENÚ INFERIOR FIJO Y RESPONSIVE CON ICONOS ACTUALIZADOS
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.card1Fondo,
          selectedItemColor: AppTheme.botonesFondo,
          unselectedItemColor: AppTheme.texto.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded, size: 22),
              activeIcon: Icon(Icons.analytics_rounded, size: 22),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded, size: 22),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, size: 22),
              label: 'Transacciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded, size: 22),
              activeIcon: Icon(Icons.receipt_long_rounded, size: 22),
              label: 'Facturas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_score_rounded, size: 22),
              activeIcon: Icon(Icons.credit_score_rounded, size: 22),
              label: 'Deudas',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORREGIDO: Inicializar páginas solo cuando los datos estén listos
    if (!_isLoadingCoupleData) {
      if (_pages.isEmpty) {
        _initializePages();
      }
    }

    // Mostrar loading mientras se cargan los datos
    if (_isLoadingCoupleData || _pages.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.fondo,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.botonesFondo,
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando datos financieros...',
                style: TextStyle(
                  color: AppTheme.texto,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.texto),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: AppTheme.texto),
            onPressed: _showUserMenu,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      extendBody: true,
      
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _showAddDataModal,
          backgroundColor: AppTheme.botonesFondo,
          foregroundColor: AppTheme.botonesTexto,
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}