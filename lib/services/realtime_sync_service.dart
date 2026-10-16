import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

typedef RealtimeTableListener = void Function(PostgresChangePayload payload);

/// One authenticated WebSocket subscription shared by the whole application.
///
/// PostgreSQL RLS still decides which rows each account receives. Screens only
/// register for the tables they render and refresh their server query when one
/// of those tables changes.
class RealtimeSyncService {
  RealtimeSyncService._();

  static final RealtimeSyncService instance = RealtimeSyncService._();

  final Map<int, ({Set<String> tables, RealtimeTableListener listener})>
      _listeners = {};
  int _nextListenerId = 0;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  String? _connectedUserId;

  Future<void> initialize() async {
    if (_authSubscription != null) return;
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
      (state) => _connectForUser(state.session?.user.id),
    );
    await _connectForUser(SupabaseService.currentUserId);
  }

  VoidCallback subscribe(
    Iterable<String> tables,
    RealtimeTableListener listener,
  ) {
    final id = _nextListenerId++;
    _listeners[id] = (tables: tables.toSet(), listener: listener);
    return () => _listeners.remove(id);
  }

  Future<void> _connectForUser(String? userId) async {
    if (_connectedUserId == userId && _channel != null) return;
    final oldChannel = _channel;
    _channel = null;
    _connectedUserId = userId;
    if (oldChannel != null) {
      await SupabaseService.client.removeChannel(oldChannel);
    }
    if (userId == null) return;

    _channel = SupabaseService.client
        .channel('codesnap-app-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: _dispatch,
        )
        .subscribe((status, error) {
      if (error != null) {
        debugPrint('Realtime subscription error: $error');
      }
    });
  }

  void _dispatch(PostgresChangePayload payload) {
    final snapshot = _listeners.values.toList(growable: false);
    for (final entry in snapshot) {
      if (entry.tables.contains(payload.table)) {
        entry.listener(payload);
      }
    }
  }
}
