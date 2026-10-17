import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ChatMessageRecord {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String messageType;
  final String? codeSnippet;
  final String? codeLanguage;
  final String? mediaPath;
  final String? mediaUrl;
  final String? mediaName;
  final String? replyToMessageId;
  final DateTime createdAt;
  final bool isRead;
  final bool isStarred;
  final bool isPinned;
  final List<String> reactions;

  const ChatMessageRecord({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.messageType,
    required this.createdAt,
    required this.isRead,
    required this.isStarred,
    required this.isPinned,
    required this.reactions,
    this.codeSnippet,
    this.codeLanguage,
    this.mediaPath,
    this.mediaUrl,
    this.mediaName,
    this.replyToMessageId,
  });
}

class ChatConversationRecord {
  final String id;
  final String kind;
  final String name;
  final String role;
  final String avatarUrl;
  final DateTime updatedAt;
  final List<ChatMessageRecord> messages;

  const ChatConversationRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.updatedAt,
    required this.messages,
  });
}

class ChatService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<ChatConversationRecord>> fetchConversations() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return const [];

    final membershipRows = List<Map<String, dynamic>>.from(await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', userId));
    final conversationIds = membershipRows
        .map((row) => row['conversation_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (conversationIds.isEmpty) return const [];

    final results = await Future.wait([
      _client
          .from('conversations')
          .select()
          .inFilter('id', conversationIds)
          .order('last_message_at', ascending: false, nullsFirst: false),
      _client
          .from('conversation_participants')
          .select('conversation_id,user_id')
          .inFilter('conversation_id', conversationIds),
      _client
          .from('messages')
          .select()
          .inFilter('conversation_id', conversationIds)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true)
          .limit(1000),
    ]);

    final conversationRows = List<Map<String, dynamic>>.from(results[0]);
    final participantRows = List<Map<String, dynamic>>.from(results[1]);
    final messageRows = List<Map<String, dynamic>>.from(results[2]);
    final profileIds = participantRows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profileRows = profileIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from(SupabaseService.tableProfiles)
            .select('id,username,full_name,avatar_url,headline')
            .inFilter('id', profileIds));
    final profilesById = {
      for (final row in profileRows) row['id'].toString(): row,
    };

    final messageIds = messageRows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final flagRows = messageIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from('message_user_flags')
            .select()
            .eq('user_id', userId)
            .inFilter('message_id', messageIds));
    final reactionRows = messageIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from('message_reactions')
            .select('message_id,emoji')
            .inFilter('message_id', messageIds));
    final flagsByMessage = {
      for (final row in flagRows) row['message_id'].toString(): row,
    };
    final reactionsByMessage = <String, List<String>>{};
    for (final row in reactionRows) {
      reactionsByMessage
          .putIfAbsent(row['message_id'].toString(), () => <String>[])
          .add(row['emoji']?.toString() ?? '');
    }

    final messagesByConversation = <String, List<ChatMessageRecord>>{};
    for (final row in messageRows) {
      final mediaPath = row['media_path']?.toString();
      String? mediaUrl;
      if (mediaPath != null && mediaPath.isNotEmpty) {
        mediaUrl = await _client.storage
            .from(SupabaseService.bucketChatMedia)
            .createSignedUrl(mediaPath, 3600);
      }
      final id = row['id'].toString();
      final flag = flagsByMessage[id];
      final record = ChatMessageRecord(
        id: id,
        conversationId: row['conversation_id'].toString(),
        senderId: row['sender_id'].toString(),
        text: row['text']?.toString() ?? '',
        messageType: row['message_type']?.toString() ?? 'text',
        codeSnippet: row['code_snippet']?.toString(),
        codeLanguage: row['code_language']?.toString(),
        mediaPath: mediaPath,
        mediaUrl: mediaUrl,
        mediaName: row['media_name']?.toString(),
        replyToMessageId: row['reply_to_message_id']?.toString(),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isRead: row['is_read'] == true,
        isStarred: flag?['is_starred'] == true,
        isPinned: flag?['is_pinned'] == true,
        reactions: (reactionsByMessage[id] ?? const [])
            .where((emoji) => emoji.isNotEmpty)
            .toList(growable: false),
      );
      messagesByConversation
          .putIfAbsent(record.conversationId, () => <ChatMessageRecord>[])
          .add(record);
    }

    return conversationRows.map((row) {
      final id = row['id'].toString();
      final participantIds = participantRows
          .where((part) => part['conversation_id'].toString() == id)
          .map((part) => part['user_id'].toString())
          .toList(growable: false);
      final peerId = participantIds.firstWhere(
        (id) => id != userId,
        orElse: () => userId,
      );
      final peer = profilesById[peerId] ?? const <String, dynamic>{};
      final fullName = peer['full_name']?.toString().trim();
      final username = peer['username']?.toString().trim();
      final title = row['title']?.toString().trim();
      final name = row['kind'] == 'group' && title != null && title.isNotEmpty
          ? title
          : (fullName != null && fullName.isNotEmpty
              ? fullName
              : (username != null && username.isNotEmpty
                  ? username
                  : 'CodeSnap account'));
      return ChatConversationRecord(
        id: id,
        kind: row['kind']?.toString() ?? 'direct',
        name: name,
        role: peer['headline']?.toString() ?? '',
        avatarUrl:
            (row['kind'] == 'group' ? row['avatar_url'] : peer['avatar_url'])
                    ?.toString() ??
                '',
        updatedAt: DateTime.tryParse(
              (row['last_message_at'] ?? row['updated_at'] ?? row['created_at'])
                      ?.toString() ??
                  '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        messages: messagesByConversation[id] ?? const [],
      );
    }).toList(growable: false);
  }

  static Future<String> getOrCreateDirectConversation(
      String otherUserId) async {
    final id = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {'other_user_id': otherUserId},
    );
    return id.toString();
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? codeSnippet,
    String? codeLanguage,
    String? replyToMessageId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    await _client.from(SupabaseService.tableMessages).insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'text': text,
      'message_type': codeSnippet == null ? 'text' : 'code',
      'code_snippet': codeSnippet,
      'code_language': codeLanguage,
      'reply_to_message_id': replyToMessageId,
    });
  }

  static Future<void> sendMedia({
    required String conversationId,
    required String messageType,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    String text = '',
    String? replyToMessageId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final objectPath =
        '$conversationId/$userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage.from(SupabaseService.bucketChatMedia).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    try {
      await _client.from(SupabaseService.tableMessages).insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'text': text,
        'message_type': messageType,
        'media_path': objectPath,
        'media_name': fileName,
        'media_mime_type': mimeType,
        'reply_to_message_id': replyToMessageId,
      });
    } catch (_) {
      await _client.storage
          .from(SupabaseService.bucketChatMedia)
          .remove([objectPath]);
      rethrow;
    }
  }

  static Future<void> setMessageFlags({
    required String messageId,
    required bool isStarred,
    required bool isPinned,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    await _client.from('message_user_flags').upsert({
      'message_id': messageId,
      'user_id': userId,
      'is_starred': isStarred,
      'is_pinned': isPinned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required bool enabled,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    if (enabled) {
      await _client.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
    } else {
      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    }
  }

  static Future<void> deleteMessage(String messageId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    final message = await _client
        .from(SupabaseService.tableMessages)
        .select('sender_id,media_path')
        .eq('id', messageId)
        .maybeSingle();
    if (message == null || message['sender_id']?.toString() != userId) {
      throw StateError('Only the sender can delete this message for everyone.');
    }
    final deleted = await _client
        .from(SupabaseService.tableMessages)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', messageId)
        .eq('sender_id', userId)
        .select('id')
        .maybeSingle();
    if (deleted == null) {
      throw StateError('Only the sender can delete this message for everyone.');
    }
    final mediaPath = message['media_path']?.toString();
    if (mediaPath != null && mediaPath.isNotEmpty) {
      try {
        await _client.storage
            .from(SupabaseService.bucketChatMedia)
            .remove([mediaPath]);
      } catch (_) {
        // The message is already hidden for every participant. Storage cleanup
        // can be retried independently if a stale object policy blocks it.
      }
    }
  }

  static Future<String> startCall({
    required String conversationId,
    required bool video,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw const AuthException('Authentication required');
    final row = await _client
        .from('chat_calls')
        .insert({
          'conversation_id': conversationId,
          'initiator_id': userId,
          'call_type': video ? 'video' : 'audio',
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  static Future<void> updateCall(String callId, String status) async {
    final values = <String, dynamic>{'status': status};
    if (status == 'accepted') {
      values['answered_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (status == 'ended' || status == 'declined' || status == 'missed') {
      values['ended_at'] = DateTime.now().toUtc().toIso8601String();
    }
    await _client.from('chat_calls').update(values).eq('id', callId);
  }
}
