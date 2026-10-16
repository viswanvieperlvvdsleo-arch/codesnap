import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'browser_launcher.dart';
import 'supabase_service.dart';

class PaymentRecord {
  final String id;
  final String itemTitle;
  final String itemId;
  final double amount;
  final String currency;
  final String timestamp;
  final String status;
  final String paymentMethod;
  final String receiptId;

  const PaymentRecord({
    required this.id,
    required this.itemTitle,
    required this.itemId,
    required this.amount,
    this.currency = 'INR',
    required this.timestamp,
    this.status = 'Success',
    required this.paymentMethod,
    required this.receiptId,
  });
}

class CheckoutResult {
  final bool alreadyPurchased;
  final bool checkoutOpened;

  const CheckoutResult({
    required this.alreadyPurchased,
    required this.checkoutOpened,
  });
}

class PaymentService {
  PaymentService._() {
    unawaited(refreshPurchases());
  }

  static final PaymentService instance = PaymentService._();

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  final Set<String> _unlockedItemIds = {};
  final List<PaymentRecord> _history = [];

  SupabaseClient get _client => SupabaseService.client;

  List<PaymentRecord> get history => List.unmodifiable(_history);

  bool isItemUnlocked(String itemId) => _unlockedItemIds.contains(itemId);

  Future<void> refreshPurchases() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _unlockedItemIds.clear();
      _history.clear();
      changeNotifier.value++;
      return;
    }

    final rows = await _client
        .from(SupabaseService.tableNotePurchases)
        .select(
          'id, document_id, amount, currency, status, purchased_at, '
          'payment_method, provider_payment_id, note_documents(title)',
        )
        .eq('status', 'completed')
        .order('purchased_at', ascending: false);

    _unlockedItemIds
      ..clear()
      ..addAll(
        List<Map<String, dynamic>>.from(rows)
            .map((row) => row['document_id']?.toString())
            .whereType<String>(),
      );

    _history
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(rows).map(_recordFromRow));
    changeNotifier.value++;
  }

  Future<CheckoutResult> startCheckout({required String itemId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before purchasing a PDF.');
    }

    final response = await _client.functions.invoke(
      'create-note-checkout',
      body: {
        'document_id': itemId,
        'return_url': Uri.base.toString(),
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['already_purchased'] == true) {
      await refreshPurchases();
      return const CheckoutResult(
        alreadyPurchased: true,
        checkoutOpened: false,
      );
    }

    final checkoutUrl = data['checkout_url']?.toString();
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw StateError(data['error']?.toString() ?? 'Checkout is unavailable.');
    }
    openInBrowser(checkoutUrl);
    return const CheckoutResult(
      alreadyPurchased: false,
      checkoutOpened: true,
    );
  }

  Future<bool> waitForCompletedPurchase(
    String itemId, {
    int attempts = 20,
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      await refreshPurchases();
      if (isItemUnlocked(itemId)) return true;
      if (attempt < attempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  PaymentRecord _recordFromRow(Map<String, dynamic> row) {
    final document = row['note_documents'];
    final title = document is Map
        ? document['title']?.toString() ?? 'PDF purchase'
        : 'PDF purchase';
    final purchasedAt = DateTime.tryParse(row['purchased_at']?.toString() ?? '');
    final localDate = purchasedAt?.toLocal();
    final timestamp = localDate == null
        ? 'Completed'
        : '${localDate.year.toString().padLeft(4, '0')}-'
            '${localDate.month.toString().padLeft(2, '0')}-'
            '${localDate.day.toString().padLeft(2, '0')}';
    return PaymentRecord(
      id: row['id'].toString(),
      itemTitle: title,
      itemId: row['document_id'].toString(),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      currency: row['currency']?.toString() ?? 'INR',
      timestamp: timestamp,
      status: 'Success',
      paymentMethod: row['payment_method']?.toString() ?? 'Secure checkout',
      receiptId: row['provider_payment_id']?.toString() ?? row['id'].toString(),
    );
  }
}
