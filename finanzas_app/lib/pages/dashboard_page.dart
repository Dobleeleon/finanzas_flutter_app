// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../services/firebase_service.dart';
import '../pages/bills_page.dart';
import '../pages/debts_page.dart';
import '../pages/transactions_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String coupleId;
  final Map<String, dynamic> coupleData;

  const DashboardPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.coupleId,
    required this.coupleData,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _totalDebt = 0;
  double _monthlyInterest = 0;
  double _individualBalance = 0;
  List<Map<String, dynamic>> _upcomingBills = [];
  List<Map<String, dynamic>> _activeDebts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _coupleInfo;
  
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      setState(callback);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _loadFinancialData();
      await _loadCoupleData();

    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'Error al cargar los datos: $e';
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFinancialData() async {
    final now = DateTime.now();
    double totalIncome = 0;
    double totalExpenses = 0;
    double individualIncome = 0;
    double individualExpenses = 0;

    try {
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final allTransactionsResult = await FirebaseService.getTransactions(
        widget.coupleId,
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
      );

      if (allTransactionsResult['success'] == true) {
        final transactions = allTransactionsResult['data'] as List<dynamic>;
        
        for (var transaction in transactions) {
          final amount = (transaction['amount'] ?? 0.0).toDouble();
          final type = transaction['type']?.toString() ?? '';
          final userId = transaction['userId']?.toString() ?? '';
          
          if (type == 'income') {
            totalIncome += amount;
          } else if (type == 'expense') {
            totalExpenses += amount;
          }
          
          if (userId == widget.userId) {
            if (type == 'income') {
              individualIncome += amount;
            } else if (type == 'expense') {
              individualExpenses += amount;
            }
          }
        }
      }

      final billsResult = await FirebaseService.getBills(widget.coupleId);
      if (billsResult['success'] == true) {
        final bills = billsResult['data'] as List<dynamic>;
        
        for (var bill in bills) {
          if (bill['paid'] == true) {
            final paidBy = bill['paidBy']?.toString() ?? '';
            final paidDate = bill['updatedAt'] ?? bill['createdAt'];
            
            if (paidDate != null) {
              final paidDateTime = _parseTimestamp(paidDate);
              final isCurrentMonth = paidDateTime.year == now.year && 
                                   paidDateTime.month == now.month;
              
              if (isCurrentMonth) {
                final billAmount = (bill['amount'] ?? 0.0).toDouble();
                
                totalExpenses += billAmount;
                
                if (paidBy == widget.userId) {
                  individualExpenses += billAmount;
                }
              }
            }
          }
        }
      }

      final coupleBalance = totalIncome - totalExpenses;
      final individualBalance = individualIncome - individualExpenses;

      _safeSetState(() {
        _totalIncome = totalIncome;
        _totalExpenses = totalExpenses;
        _individualBalance = individualBalance;
      });

    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'Error al cargar datos financieros: $e';
      });
    }
  }

  Future<void> _loadCoupleData() async {
    if (_isDisposed) return;

    try {
      if (widget.coupleData.isNotEmpty) {
        _safeSetState(() {
          _coupleInfo = widget.coupleData;
        });
      } else if (widget.coupleId.isNotEmpty) {
        final coupleResult = await FirebaseService.getCouple(widget.coupleId);
        if (coupleResult['success'] == true) {
          _safeSetState(() {
            _coupleInfo = coupleResult['data'];
          });
        }
      }

      final billsResult = await FirebaseService.getBills(widget.coupleId);
      if (billsResult['success'] == true) {
        _processBillsData(billsResult['data'] as List<dynamic>);
      }

      final debtsResult = await FirebaseService.getDebts(widget.coupleId);
      if (debtsResult['success'] == true) {
        _processDebtsData(debtsResult['data'] as List<dynamic>);
      }

    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'Error al cargar datos de pareja: $e';
      });
    }
  }

  void _processBillsData(List<dynamic> bills) {
    try {
      final now = DateTime.now();
      final upcomingBills = bills
          .where((bill) => 
              bill['paid'] == false && 
              bill['dueDate'] != null)
          .map((bill) {
        final dueDate = _parseTimestamp(bill['dueDate']);
        final daysUntilDue = dueDate.difference(now).inDays;
        
        return {
          'id': bill['id'],
          'title': bill['description'] ?? 'Sin título',
          'amount': (bill['amount'] ?? 0.0).toDouble(),
          'dueDate': dueDate,
          'daysUntilDue': daysUntilDue,
          'category': bill['category'] ?? 'General',
        };
      })
          .where((bill) => bill['daysUntilDue'] >= 0)
          .toList()
        ..sort((a, b) => a['daysUntilDue'].compareTo(b['daysUntilDue']));

      _safeSetState(() {
        _upcomingBills = upcomingBills.take(3).toList();
      });
    } catch (e) {
      // Silenciar error de procesamiento de facturas
    }
  }

  void _processDebtsData(List<dynamic> debts) {
    try {
      double totalDebt = 0;
      double monthlyInterest = 0;
      List<Map<String, dynamic>> activeDebts = [];

      for (var debt in debts) {
        final currentAmount = (debt['currentAmount'] ?? debt['amount'] ?? 0.0).toDouble();
        final interestRate = (debt['interestRate'] ?? 0.0).toDouble();
        final status = debt['status'] ?? 'pending';
        
        if (status != 'paid' && currentAmount > 0) {
          totalDebt += currentAmount;
          monthlyInterest += currentAmount * (interestRate / 100);
          
          activeDebts.add({
            'id': debt['id'],
            'title': debt['description'] ?? 'Sin título',
            'amount': currentAmount,
            'interestRate': interestRate,
            'creditor': debt['creditor'] ?? 'Sin especificar',
            'status': status,
          });
        }
      }

      _safeSetState(() {
        _totalDebt = totalDebt;
        _monthlyInterest = monthlyInterest;
        _activeDebts = activeDebts.take(2).toList();
      });
    } catch (e) {
      // Silenciar error de procesamiento de deudas
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }

  void _refreshData() {
    if (_isDisposed) return;
    
    _safeSetState(() {
      _isLoading = true;
    });
    
    _loadDashboardData();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _navigateToBills() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillsPage(
          userName: widget.userName,
          userId: widget.userId,
          coupleId: widget.coupleId,
          coupleData: widget.coupleData,
        ),
      ),
    ).then((_) {
      if (!_isDisposed) {
        _refreshData();
      }
    });
  }

  void _navigateToDebts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtsPage(
          userName: widget.userName,
          userId: widget.userId,
          coupleId: widget.coupleId,
          coupleData: widget.coupleData,
        ),
      ),
    ).then((_) {
      if (!_isDisposed) {
        _refreshData();
      }
    });
  }

  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionsPage(
          userName: widget.userName,
          userId: widget.userId,
          coupleId: widget.coupleId,
          coupleData: widget.coupleData,
        ),
      ),
    ).then((_) {
      if (!_isDisposed) {
        _refreshData();
      }
    });
  }

  // ========== MÉTODOS DE UI ==========

  Widget _buildErrorCard() {
    return Container(
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
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red.shade600,
              size: 18,
            ),
            onPressed: () {
              _safeSetState(() {
                _errorMessage = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
    String title,
    String amount,
    String subtitle,
    Color cardColor,
    Color textColor,
    IconData icon,
    Color trendColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  Icon(
                    icon,
                    color: trendColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtItem(String title, double amount, double interestRate, String creditor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.card1Fondo.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.credit_card,
              color: Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.card2Texto,
                  ),
                ),
                Text(
                  creditor,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.card2Texto.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.card2Texto,
                ),
              ),
              Text(
                '$interestRate% interés',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(String title, double amount, int daysLeft, IconData icon) {
    Color statusColor = daysLeft <= 3 ? Colors.red : daysLeft <= 7 ? Colors.orange : Colors.blue;
    String statusText = daysLeft <= 3 ? '¡Vence pronto!' : 
                       daysLeft <= 7 ? 'Vence en $daysLeft días' : 
                       'Vence en $daysLeft días';
    
    return Card(
      color: AppTheme.card1Fondo,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.botonesFondo,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.botonesTexto,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.texto,
          ),
        ),
        subtitle: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.texto,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$daysLeft días',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBills() {
    return Card(
      color: AppTheme.card1Fondo,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
            SizedBox(height: 12),
            Text(
              'No hay facturas pendientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('¡Todo al día!'),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'servicios':
        return Icons.build;
      case 'deudas':
        return Icons.credit_card;
      case 'entretenimiento':
        return Icons.movie;
      case 'alimentación':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'salud':
        return Icons.local_hospital;
      default:
        return Icons.receipt;
    }
  }

  String _getPartnerName() {
    if (_coupleInfo == null) return '';
    final user1Id = _coupleInfo!['user1Id'];
    final user2Id = _coupleInfo!['user2Id'];
    
    if (user1Id == widget.userId) {
      return _coupleInfo!['user2Name'] ?? 'Pareja';
    } else {
      return _coupleInfo!['user1Name'] ?? 'Pareja';
    }
  }

  // ========== VISTA INDIVIDUAL ==========

  Widget _buildIndividualView() {
    final coupleBalance = _totalIncome - _totalExpenses;
    
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Mi Dashboard'),
        backgroundColor: AppTheme.card2Fondo,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.card2Texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIndividualHeader(),
                    
                    if (_errorMessage.isNotEmpty) 
                      _buildErrorCard(),
                    
                    const SizedBox(height: 24),
                    _buildIndividualFinanceGrid(coupleBalance),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIndividualHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola,',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: AppTheme.texto,
          ),
        ),
        Text(
          widget.userName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.texto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestión Financiera Personal',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.texto.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        _buildBalanceCard(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card1Fondo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tu Saldo Personal',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.texto.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(_individualBalance),
            style: TextStyle(
              color: _individualBalance >= 0 ? Colors.green : Colors.red,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _individualBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _individualBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: _individualBalance >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _individualBalance >= 0 ? 'Saldo Positivo' : 'Saldo Negativo',
                  style: TextStyle(
                    color: _individualBalance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus ingresos - Tus gastos',
            style: TextStyle(
              color: AppTheme.texto.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualFinanceGrid(double coupleBalance) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFinanceCard(
          'Ingresos del Mes',
          _formatCurrency(_totalIncome),
          'Total en tu cuenta',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          Icons.arrow_upward,
          Colors.green,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Gastos del Mes',
          _formatCurrency(_totalExpenses),
          'Total de tus gastos',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          Icons.arrow_downward,
          Colors.red,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Balance Mensual',
          _formatCurrency(coupleBalance),
          coupleBalance >= 0 ? 'Superávit' : 'Déficit',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          coupleBalance >= 0 ? Icons.trending_up : Icons.trending_down,
          coupleBalance >= 0 ? Colors.green : Colors.red,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Tu Situación',
          _individualBalance >= 0 ? 'Positivo' : 'Atención',
          _formatCurrency(_individualBalance.abs()),
          _individualBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          _individualBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
          _individualBalance >= 0 ? Icons.check_circle : Icons.warning,
          _individualBalance >= 0 ? Colors.green : Colors.red,
          onTap: _navigateToTransactions,
        ),
      ],
    );
  }

  // ========== VISTA EN PAREJA ==========

  Widget _buildCoupleView() {
    final coupleBalance = _totalIncome - _totalExpenses;
    
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Dashboard Compartido'),
        backgroundColor: AppTheme.card2Fondo,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.card2Texto),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoupleHeader(),
                    
                    if (_errorMessage.isNotEmpty) 
                      _buildErrorCard(),
                    
                    const SizedBox(height: 24),
                    _buildCoupleFinanceGrid(coupleBalance),
                    const SizedBox(height: 24),
                    _buildDebtsSection(),
                    const SizedBox(height: 24),
                    _buildBillsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCoupleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola,',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: AppTheme.texto,
          ),
        ),
        Text(
          widget.userName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.texto,
          ),
        ),
        if (_coupleInfo != null) ...[
          const SizedBox(height: 8),
          Text(
            'Pareja: ${_getPartnerName()}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.texto.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildBalanceCard(),
      ],
    );
  }

  Widget _buildCoupleFinanceGrid(double coupleBalance) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFinanceCard(
          'Ingresos del Mes',
          _formatCurrency(_totalIncome),
          'Total en pareja',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          Icons.arrow_upward,
          Colors.green,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Gastos del Mes',
          _formatCurrency(_totalExpenses),
          'Total en pareja',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          Icons.arrow_downward,
          Colors.red,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Balance Mensual',
          _formatCurrency(coupleBalance),
          coupleBalance >= 0 ? 'Superávit' : 'Déficit',
          AppTheme.card1Fondo,
          AppTheme.card1Texto,
          coupleBalance >= 0 ? Icons.trending_up : Icons.trending_down,
          coupleBalance >= 0 ? Colors.green : Colors.red,
          onTap: _navigateToTransactions,
        ),
        _buildFinanceCard(
          'Tu Saldo Personal',
          _formatCurrency(_individualBalance),
          _individualBalance >= 0 ? 'Positivo' : 'Negativo',
          _individualBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          _individualBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
          _individualBalance >= 0 ? Icons.account_balance_wallet : Icons.money_off,
          _individualBalance >= 0 ? Colors.green : Colors.red,
          onTap: _navigateToTransactions,
        ),
      ],
    );
  }

  Widget _buildDebtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deudas Compartidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.texto,
              ),
            ),
            InkWell(
              onTap: _navigateToDebts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.botonesFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.botonesTexto,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.botonesTexto,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDebtsCard(),
      ],
    );
  }

  Widget _buildDebtsCard() {
    return Card(
      color: AppTheme.card2Fondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deuda Total',
                      style: TextStyle(
                        color: AppTheme.card2Texto,
                      ),
                    ),
                    Text(
                      _formatCurrency(_totalDebt),
                      style: TextStyle(
                        color: AppTheme.card2Texto,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Interés Mensual',
                      style: TextStyle(
                        color: AppTheme.card2Texto,
                      ),
                    ),
                    Text(
                      _formatCurrency(_monthlyInterest),
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
            
            if (_activeDebts.isNotEmpty) 
              ..._activeDebts.map((debt) => _buildDebtItem(
                debt['title'],
                debt['amount'],
                debt['interestRate'],
                debt['creditor'],
              )).toList(),
            
            if (_activeDebts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_score,
                      size: 40,
                      color: AppTheme.card2Texto.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay deudas activas',
                      style: TextStyle(
                        color: AppTheme.card2Texto,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Facturas Próximas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.texto,
              ),
            ),
            InkWell(
              onTap: _navigateToBills,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.botonesFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.botonesTexto,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.botonesTexto,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_upcomingBills.isEmpty) 
          _buildEmptyBills()
        else 
          Column(
            children: _upcomingBills.map((bill) => _buildBillItem(
              bill['title'],
              bill['amount'],
              bill['daysUntilDue'],
              _getCategoryIcon(bill['category']),
            )).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coupleId.isEmpty) {
      return _buildIndividualView();
    }
    return _buildCoupleView();
  }
}