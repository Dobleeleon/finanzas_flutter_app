// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== MANEJO DE ERRORES ==========
  static Map<String, dynamic> _handleError(String operation, dynamic e, {String? customMessage}) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return {'success': false, 'error': 'Error de conexión. Verifica tu internet'};
        case 'user-not-found':
          return {'success': false, 'error': 'Usuario no encontrado'};
        case 'wrong-password':
          return {'success': false, 'error': 'Contraseña incorrecta'};
        case 'email-already-in-use':
          return {'success': false, 'error': 'El email ya está en uso'};
        case 'invalid-email':
          return {'success': false, 'error': 'Email inválido'};
        case 'weak-password':
          return {'success': false, 'error': 'La contraseña es muy débil'};
        default:
          return {'success': false, 'error': customMessage ?? e.message ?? 'Error en $operation'};
      }
    }
    
    return {'success': false, 'error': customMessage ?? e.toString()};
  }

  static Map<String, dynamic> _handleSuccess([String? message, dynamic data]) {
    return {'success': true, 'message': message, 'data': data};
  }

  // ========== AUTH CON EMAIL Y CONTRASEÑA ==========
  static Future<Map<String, dynamic>> registerUser(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': userCredential.user!.email,
        'monthlyIncome': 0.0,
        'coupleId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'provider': 'email',
      });
      
      return _handleSuccess('Usuario registrado correctamente', userCredential.user!.uid);
    } catch (e) {
      return _handleError('registerUser', e, customMessage: 'Error al registrar usuario');
    }
  }

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      return _handleSuccess('Inicio de sesión exitoso', userCredential.user!.uid);
    } catch (e) {
      return _handleError('loginUser', e, customMessage: 'Error al iniciar sesión');
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return {'success': false, 'error': 'Perfil de usuario no encontrado'};
      }

      final userData = doc.data()!;
      userData['userId'] = doc.id;
      
      return _handleSuccess('Perfil obtenido', userData);
    } catch (e) {
      return _handleError('getUserProfile', e);
    }
  }

  static Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _auth.signOut();
      return _handleSuccess('Sesión cerrada correctamente');
    } catch (e) {
      return _handleError('signOut', e);
    }
  }

  // ========== MÉTODOS ADICIONALES ÚTILES ==========
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  static Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
      return _handleSuccess('Perfil actualizado correctamente');
    } catch (e) {
      return _handleError('updateUserProfile', e);
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return _handleSuccess('Correo de recuperación enviado');
    } catch (e) {
      return _handleError('resetPassword', e, customMessage: 'Error al enviar correo de recuperación');
    }
  }

  // ========== GESTIÓN DE PAREJAS ==========
  static Future<Map<String, dynamic>> createCouple(String userId, String partnerEmail) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'error': 'Usuario principal no encontrado'};
      }
      
      final userData = userDoc.data()!;
      if (userData['coupleId'] != null && userData['coupleId'].isNotEmpty) {
        return {'success': false, 'error': 'Ya tienes una pareja vinculada'};
      }

      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: partnerEmail.toLowerCase())
          .get();

      if (usersSnapshot.docs.isEmpty) {
        return {'success': false, 'error': 'No existe un usuario con ese email'};
      }

      final partnerDoc = usersSnapshot.docs.first;
      final partnerId = partnerDoc.id;
      final partnerData = partnerDoc.data() as Map<String, dynamic>;

      if (partnerId == userId) {
        return {'success': false, 'error': 'No puedes vincularte contigo mismo'};
      }

      if (partnerData['coupleId'] != null && partnerData['coupleId'].isNotEmpty) {
        return {'success': false, 'error': 'Este usuario ya está vinculado a otra pareja'};
      }

      final coupleId = _firestore.collection('couples').doc().id;

      await _firestore.collection('couples').doc(coupleId).set({
        'user1Id': userId,
        'user2Id': partnerId,
        'user1Name': userData['name'],
        'user2Name': partnerData['name'],
        'user1Email': userData['email'],
        'user2Email': partnerData['email'],
        'createdAt': FieldValue.serverTimestamp(),
        'totalBalance': 0.0,
        'status': 'active',
      });

      await _firestore.collection('users').doc(userId).update({
        'coupleId': coupleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(partnerId).update({
        'coupleId': coupleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return _handleSuccess('Pareja creada exitosamente', coupleId);
    } catch (e) {
      return _handleError('createCouple', e);
    }
  }

  static Future<Map<String, dynamic>> getCouple(String coupleId) async {
    try {
      final doc = await _firestore.collection('couples').doc(coupleId).get();
      
      if (!doc.exists) {
        return {'success': false, 'error': 'Pareja no encontrada'};
      }

      final coupleData = doc.data()!;
      coupleData['coupleId'] = doc.id;
      
      return _handleSuccess('Pareja obtenida', coupleData);
    } catch (e) {
      return _handleError('getCouple', e);
    }
  }

  static Future<Map<String, dynamic>> getCoupleByUserId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      final userData = userDoc.data()!;
      final coupleId = userData['coupleId'] ?? '';

      if (coupleId.isEmpty) {
        return {'success': false, 'error': 'Usuario no tiene pareja vinculada'};
      }

      return await getCouple(coupleId);
    } catch (e) {
      return _handleError('getCoupleByUserId', e);
    }
  }

  // ========== GESTIÓN DE TRANSACCIONES ==========
  static Future<Map<String, dynamic>> getTransactions(String coupleId, {
    String? type, 
    String? category, 
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    try {
      Query query = _firestore.collection('transactions').where('coupleId', isEqualTo: coupleId);

      if (type != null && type != 'todos') {
        query = query.where('type', isEqualTo: type);
      }
      if (category != null && category != 'todos') {
        query = query.where('category', isEqualTo: category);
      }
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('date', descending: true);

      final querySnapshot = await query.get();

      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return _handleSuccess('Transacciones obtenidas', transactions);
    } catch (e) {
      return _handleError('getTransactions', e);
    }
  }

  static Future<Map<String, dynamic>> getUserTransactions(
    String coupleId, 
    String userId, {
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    try {
      Query query = _firestore.collection('transactions')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('date', descending: true);

      final querySnapshot = await query.get();

      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return _handleSuccess('Transacciones del usuario obtenidas', transactions);
    } catch (e) {
      return _handleError('getUserTransactions', e);
    }
  }

  static Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> transactionData, String coupleId) async {
    try {
      transactionData['coupleId'] = coupleId;
      transactionData['createdAt'] = FieldValue.serverTimestamp();
      transactionData['date'] = Timestamp.fromDate(transactionData['date'] ?? DateTime.now());

      final docRef = await _firestore.collection('transactions').add(transactionData);
      
      return _handleSuccess('Transacción agregada correctamente', docRef.id);
    } catch (e) {
      return _handleError('addTransaction', e);
    }
  }

  static Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
      return _handleSuccess('Transacción eliminada correctamente');
    } catch (e) {
      return _handleError('deleteTransaction', e);
    }
  }

  static Future<Map<String, dynamic>> updateTransaction(String transactionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('transactions').doc(transactionId).update(updates);
      return _handleSuccess('Transacción actualizada correctamente');
    } catch (e) {
      return _handleError('updateTransaction', e);
    }
  }

  // ========== GESTIÓN DE FACTURAS ==========
  static Future<Map<String, dynamic>> getBills(String coupleId, {
    String? status, 
    String? category, 
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    try {
      Query query = _firestore.collection('bills').where('coupleId', isEqualTo: coupleId);

      if (status != null && status != 'all') {
        query = query.where('paid', isEqualTo: status == 'paid');
      }
      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }
      if (startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('dueDate', descending: false);

      final querySnapshot = await query.get();

      final bills = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return _handleSuccess('Facturas obtenidas', bills);
    } catch (e) {
      return _handleError('getBills', e);
    }
  }

  static Future<Map<String, dynamic>> addBill(Map<String, dynamic> billData, String coupleId) async {
    try {
      billData['coupleId'] = coupleId;
      billData['createdAt'] = FieldValue.serverTimestamp();
      billData['dueDate'] = Timestamp.fromDate(billData['dueDate'] ?? DateTime.now());
      billData['paid'] = billData['paid'] ?? false;
      billData['paidBy'] = billData['paidBy'] ?? '';
      billData['paidByName'] = billData['paidByName'] ?? '';
      billData['paidAt'] = billData['paidAt'] ?? null;

      final docRef = await _firestore.collection('bills').add(billData);
      
      return _handleSuccess('Factura agregada correctamente', docRef.id);
    } catch (e) {
      return _handleError('addBill', e);
    }
  }

  static Future<Map<String, dynamic>> markBillAsPaid(
    String billId, 
    String userId, 
    String userName
  ) async {
    try {
      final updates = {
        'paid': true,
        'paidBy': userId,
        'paidByName': userName,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bills').doc(billId).update(updates);
      
      return _handleSuccess('Factura marcada como pagada');
    } catch (e) {
      return _handleError('markBillAsPaid', e);
    }
  }

  static Future<Map<String, dynamic>> markBillAsUnpaid(String billId) async {
    try {
      final updates = {
        'paid': false,
        'paidBy': '',
        'paidByName': '',
        'paidAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bills').doc(billId).update(updates);
      
      return _handleSuccess('Factura marcada como no pagada');
    } catch (e) {
      return _handleError('markBillAsUnpaid', e);
    }
  }

  static Future<Map<String, dynamic>> deleteBill(String billId) async {
    try {
      await _firestore.collection('bills').doc(billId).delete();
      return _handleSuccess('Factura eliminada correctamente');
    } catch (e) {
      return _handleError('deleteBill', e);
    }
  }

  static Future<Map<String, dynamic>> updateBill(String billId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('bills').doc(billId).update(updates);
      return _handleSuccess('Factura actualizada correctamente');
    } catch (e) {
      return _handleError('updateBill', e);
    }
  }

  // ========== GESTIÓN DE DEUDAS ==========
  static Future<Map<String, dynamic>> getDebts(String coupleId, {
    String? status, 
    String? category, 
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    try {
      Query query = _firestore.collection('debts').where('coupleId', isEqualTo: coupleId);

      if (status != null && status != 'all' && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (category != null && category != 'all' && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();

      final debts = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return _handleSuccess('Deudas obtenidas', debts);
    } catch (e) {
      return _handleError('getDebts', e);
    }
  }

  static Future<Map<String, dynamic>> addDebt(Map<String, dynamic> debtData, String coupleId) async {
    try {
      debtData['coupleId'] = coupleId;
      debtData['createdAt'] = FieldValue.serverTimestamp();
      debtData['dueDate'] = Timestamp.fromDate(debtData['dueDate'] ?? DateTime.now().add(const Duration(days: 30)));
      debtData['status'] = debtData['status'] ?? 'pending';
      debtData['currentAmount'] = debtData['currentAmount'] ?? debtData['amount'];

      final docRef = await _firestore.collection('debts').add(debtData);
      
      return _handleSuccess('Deuda agregada correctamente', docRef.id);
    } catch (e) {
      return _handleError('addDebt', e);
    }
  }

  static Future<Map<String, dynamic>> deleteDebt(String debtId) async {
    try {
      await _firestore.collection('debts').doc(debtId).delete();
      return _handleSuccess('Deuda eliminada correctamente');
    } catch (e) {
      return _handleError('deleteDebt', e);
    }
  }

  static Future<Map<String, dynamic>> updateDebt(String debtId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('debts').doc(debtId).update(updates);
      return _handleSuccess('Deuda actualizada correctamente');
    } catch (e) {
      return _handleError('updateDebt', e);
    }
  }

  // ========== MÉTODOS ADICIONALES ==========
  static Future<Map<String, dynamic>> registerDebtPayment(
    String debtId, 
    double paymentAmount, 
    String userId, 
    String userName,
    String notes
  ) async {
    try {
      final debtDoc = await _firestore.collection('debts').doc(debtId).get();
      if (!debtDoc.exists) {
        return {'success': false, 'error': 'Deuda no encontrada'};
      }

      final debt = debtDoc.data()!;
      final currentAmount = (debt['currentAmount'] ?? 0.0).toDouble();
      final originalAmount = (debt['amount'] ?? 0.0).toDouble();
      
      if (paymentAmount > currentAmount) {
        return {'success': false, 'error': 'El pago excede el monto actual de la deuda'};
      }

      final newAmount = currentAmount - paymentAmount;
      final totalPaid = (debt['totalPaid'] ?? 0.0).toDouble() + paymentAmount;
      final isFullyPaid = newAmount <= 0;

      final updates = {
        'currentAmount': newAmount,
        'totalPaid': totalPaid,
        'status': isFullyPaid ? 'paid' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentHistory': FieldValue.arrayUnion([
          {
            'paymentDate': FieldValue.serverTimestamp(),
            'amount': paymentAmount,
            'paidBy': userId,
            'paidByName': userName,
            'notes': notes,
            'remainingBalance': newAmount,
          }
        ]),
      };

      await _firestore.collection('debts').doc(debtId).update(updates);
      
      return _handleSuccess(
        isFullyPaid ? 'Deuda completamente pagada' : 'Pago registrado correctamente',
        {
          'newBalance': newAmount,
          'totalPaid': totalPaid,
          'isFullyPaid': isFullyPaid,
        }
      );
    } catch (e) {
      return _handleError('registerDebtPayment', e);
    }
  }

  static Future<Map<String, dynamic>> applyDebtInterest(String debtId) async {
    try {
      final debtDoc = await _firestore.collection('debts').doc(debtId).get();
      if (!debtDoc.exists) {
        return {'success': false, 'error': 'Deuda no encontrada'};
      }

      final debt = debtDoc.data()!;
      final currentAmount = (debt['currentAmount'] ?? 0.0).toDouble();
      final interestRate = (debt['interestRate'] ?? 0.0).toDouble();
      
      if (interestRate <= 0) {
        return {'success': false, 'error': 'La deuda no tiene tasa de interés'};
      }

      final interestAmount = currentAmount * (interestRate / 100);
      final newAmount = currentAmount + interestAmount;

      final updates = {
        'currentAmount': newAmount,
        'totalInterest': FieldValue.increment(interestAmount),
        'updatedAt': FieldValue.serverTimestamp(),
        'interestHistory': FieldValue.arrayUnion([
          {
            'applicationDate': FieldValue.serverTimestamp(),
            'interestRate': interestRate,
            'interestAmount': interestAmount,
            'newBalance': newAmount,
          }
        ]),
      };

      await _firestore.collection('debts').doc(debtId).update(updates);
      
      return _handleSuccess(
        'Interés aplicado correctamente',
        {
          'interestAmount': interestAmount,
          'newBalance': newAmount,
        }
      );
    } catch (e) {
      return _handleError('applyDebtInterest', e);
    }
  }

  static Map<String, dynamic> calculatePaymentPlan(
    double initialAmount,
    double interestRate,
    int numberOfMonths,
    String paymentType
  ) {
    try {
      final monthlyRate = interestRate / 100 / 12;
      List<Map<String, dynamic>> payments = [];
      double remainingBalance = initialAmount;
      double totalInterest = 0;

      double fixedPayment = 0;
      if (paymentType == 'fixed') {
        if (monthlyRate > 0) {
          fixedPayment = initialAmount * 
            (monthlyRate * pow(1 + monthlyRate, numberOfMonths)) / 
            (pow(1 + monthlyRate, numberOfMonths) - 1);
        } else {
          fixedPayment = initialAmount / numberOfMonths;
        }
      }

      for (int month = 1; month <= numberOfMonths; month++) {
        double monthlyInterest = remainingBalance * monthlyRate;
        double principalPayment;

        if (paymentType == 'fixed') {
          principalPayment = fixedPayment - monthlyInterest;
          if (principalPayment < 0) principalPayment = 0;
        } else {
          principalPayment = monthlyInterest > 0 ? 
              remainingBalance * 0.02 : 
              remainingBalance / (numberOfMonths - month + 1);
        }

        if (month == numberOfMonths || principalPayment > remainingBalance) {
          principalPayment = remainingBalance;
        }

        double monthlyPayment = monthlyInterest + principalPayment;
        remainingBalance -= principalPayment;
        totalInterest += monthlyInterest;

        payments.add({
          'month': month,
          'paymentDate': DateTime.now().add(Duration(days: 30 * month)),
          'monthlyPayment': monthlyPayment,
          'principal': principalPayment,
          'interest': monthlyInterest,
          'remainingBalance': remainingBalance > 0 ? remainingBalance : 0,
        });

        if (remainingBalance <= 0) break;
      }

      return {
        'success': true,
        'data': {
          'initialAmount': initialAmount,
          'totalInterest': totalInterest,
          'totalPayment': initialAmount + totalInterest,
          'numberOfMonths': payments.length,
          'monthlyPayment': paymentType == 'fixed' ? fixedPayment : payments.isNotEmpty ? payments.first['monthlyPayment'] : 0,
          'payments': payments,
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Error calculando plan de pagos: $e'};
    }
  }

  static Future<Map<String, dynamic>> migrateExistingBills(String coupleId, String defaultUserId, String defaultUserName) async {
    try {
      final billsResult = await getBills(coupleId);
      if (!billsResult['success']) {
        return billsResult;
      }

      final bills = billsResult['data'] as List<dynamic>;
      int migratedCount = 0;

      for (var bill in bills) {
        if (bill['paid'] == true && (bill['paidBy'] == null || bill['paidBy'] == '')) {
          await updateBill(bill['id'], {
            'paidBy': defaultUserId,
            'paidByName': defaultUserName,
          });
          migratedCount++;
        }
      }

      return _handleSuccess('Facturas migradas: $migratedCount');
    } catch (e) {
      return _handleError('migrateExistingBills', e);
    }
  }
}