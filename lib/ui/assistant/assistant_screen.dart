import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/assistant_chat.dart';
import 'knowledge_browser_screen.dart';
import 'knowledge_detail_screen.dart';
import 'widgets/chat_message_bubble.dart';

/// S-07 災害対応アシスタント（テキストチャット）。
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_UiMessage>[];
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _messages.add(_UiMessage.user(text));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final useCase = await ref.read(assistantChatUseCaseProvider.future);
      final history = [
        for (final m in _messages) ChatTurn(role: m.role, text: m.text),
      ];
      final result = await useCase.ask(userMessage: text, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(_UiMessage.fromResult(result));
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_UiMessage.assistant('回答の取得に失敗しました。資料一覧から直接確認してください。'));
        _busy = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _openChunk(AssistantChunk chunk) {
    final bundle = ref.read(assistantKbBundleProvider).value;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeDetailScreen(
          chunk: chunk,
          source: bundle?.sourceFor(chunk.sourceId),
        ),
      ),
    );
  }

  Future<void> _openBrowser() async {
    final bundle = await ref.read(assistantKbBundleProvider.future);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeBrowserScreen(bundle: bundle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kb = ref.watch(assistantKbBundleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('災害対応アシスタント'),
        actions: [
          TextButton(
            key: const Key('open_knowledge_browser'),
            onPressed: kb.isLoading ? null : _openBrowser,
            child: const Text('資料を見る'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'AI回答は参考情報です。生命の危険がある場合は119番等に連絡してください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '発災後の応急手当・避難所生活・停電対策など、'
                          '同梱資料に基づいて質問できます。\n'
                          '例: 「止血の方法は？」「避難所での感染症予防は？」',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return ChatMessageBubble(
                          key: Key('msg_$i'),
                          role: m.role,
                          text: m.text,
                          chunks: m.chunks,
                          onChunkTap: _openChunk,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('assistant_input'),
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '質問を入力…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('assistant_send'),
                    onPressed: _busy ? null : _send,
                    icon: _busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UiMessage {
  _UiMessage({required this.role, required this.text, this.chunks = const []});

  factory _UiMessage.user(String text) => _UiMessage(role: 'user', text: text);

  factory _UiMessage.assistant(
    String text, {
    List<AssistantChunk> chunks = const [],
  }) => _UiMessage(role: 'assistant', text: text, chunks: chunks);

  factory _UiMessage.fromResult(AssistantChatResult result) {
    return switch (result) {
      AssistantChatAnswer(answer: final a, chunks: final c) =>
        _UiMessage.assistant(a, chunks: c),
      AssistantChatNoResults() => _UiMessage.assistant(
        '資料に該当する情報が見つかりませんでした。「資料を見る」から一覧を確認してください。',
      ),
      AssistantChatDegraded(chunks: final c) => _UiMessage.assistant(
        '関連する資料が見つかりました。以下の出典をご確認ください。',
        chunks: c,
      ),
    };
  }

  final String role;
  final String text;
  final List<AssistantChunk> chunks;
}
