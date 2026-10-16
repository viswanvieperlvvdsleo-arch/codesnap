import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AiChatReply {
  final String threadId;
  final String text;
  final String? responseId;

  const AiChatReply({
    required this.threadId,
    required this.text,
    this.responseId,
  });
}

class AiChatHistory {
  final String? threadId;
  final List<Map<String, dynamic>> messages;

  const AiChatHistory({required this.threadId, required this.messages});
}

class AiChatService {
  static Future<AiChatHistory> fetchLatestHistory() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      return const AiChatHistory(threadId: null, messages: []);
    }
    final thread = await SupabaseService.client
        .from(SupabaseService.tableAiThreads)
        .select('id')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (thread == null) {
      return const AiChatHistory(threadId: null, messages: []);
    }
    final threadId = thread['id'].toString();
    final rows = List<Map<String, dynamic>>.from(await SupabaseService.client
        .from(SupabaseService.tableAiMessages)
        .select('id,role,content,created_at,response_id')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .limit(200));
    return AiChatHistory(threadId: threadId, messages: rows);
  }

  static Future<AiChatReply> send({
    required String message,
    String? threadId,
    String? workspaceContext,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'ai-chat',
      body: {
        'message': message,
        if (threadId != null) 'threadId': threadId,
        if (workspaceContext != null) 'context': workspaceContext,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw FunctionException(
        status: response.status,
        details: data,
        reasonPhrase: message ?? 'AI request failed',
      );
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    return AiChatReply(
      threadId: data['threadId'].toString(),
      text: data['text']?.toString() ?? '',
      responseId: data['responseId']?.toString(),
    );
  }
}
