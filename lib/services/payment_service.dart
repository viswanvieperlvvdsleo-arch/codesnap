import 'package:flutter/foundation.dart';

class PaymentRecord {
  final String id;
  final String itemTitle;
  final String itemId;
  final double amount;
  final String currency;
  final String timestamp;
  final String status; // 'Success', 'Pending', 'Failed'
  final String paymentMethod;
  final String receiptId;

  const PaymentRecord({
    required this.id,
    required this.itemTitle,
    required this.itemId,
    required this.amount,
    this.currency = 'USD',
    required this.timestamp,
    this.status = 'Success',
    required this.paymentMethod,
    required this.receiptId,
  });
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  final Set<String> _unlockedItemIds = {'book-1', 'book-3'}; // default unlocked demo items

  final List<PaymentRecord> _history = [
    const PaymentRecord(
      id: 'tx_10482',
      itemTitle: 'Flutter & Dart: Production Architecture (PDF)',
      itemId: 'book-1',
      amount: 4.99,
      timestamp: 'Today, 2:15 PM',
      status: 'Success',
      paymentMethod: 'Apple Pay •••• 4242',
      receiptId: 'REC-CS-99182',
    ),
    const PaymentRecord(
      id: 'tx_10481',
      itemTitle: 'Distributed Systems & Microservices (Full Guide)',
      itemId: 'book-3',
      amount: 6.50,
      timestamp: 'Yesterday, 6:40 PM',
      status: 'Success',
      paymentMethod: 'Credit Card •••• 8831',
      receiptId: 'REC-CS-99140',
    ),
    const PaymentRecord(
      id: 'tx_10479',
      itemTitle: 'CodeSnap Pro Monthly Developer License',
      itemId: 'sub-pro-1',
      amount: 9.99,
      timestamp: 'Sep 24, 2026',
      status: 'Success',
      paymentMethod: 'Google Pay •••• 1092',
      receiptId: 'REC-CS-98421',
    ),
  ];

  List<PaymentRecord> get history => List.unmodifiable(_history);

  bool isItemUnlocked(String itemId) => _unlockedItemIds.contains(itemId);

  Future<bool> processPayment({
    required String itemId,
    required String itemTitle,
    required double amount,
    required String method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final record = PaymentRecord(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      itemTitle: itemTitle,
      itemId: itemId,
      amount: amount,
      timestamp: 'Just now',
      status: 'Success',
      paymentMethod: method,
      receiptId: 'REC-CS-${(10000 + _history.length * 17)}',
    );

    _history.insert(0, record);
    _unlockedItemIds.add(itemId);
    changeNotifier.value++;
    return true;
  }
}
