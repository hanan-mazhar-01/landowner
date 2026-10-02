import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../shared/providers/collections.dart';
import '../../../shared/providers/portfolio.dart';
import '../data/local_ai_repository.dart';
import '../domain/ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((_) => LocalAiRepository());

@immutable
class ChatMessage {
  const ChatMessage(this.text, {required this.mine, this.grounded = true});
  final String text;
  final bool mine;
  final bool grounded;
}

@immutable
class AskState {
  const AskState({this.messages = const [], this.thinking = false});
  final List<ChatMessage> messages;
  final bool thinking;
}

class AskController extends Notifier<AskState> {
  @override
  AskState build() => const AskState();

  Future<void> ask(String q) async {
    final text = q.trim();
    if (text.isEmpty || state.thinking) return;
    state = AskState(messages: [...state.messages, ChatMessage(text, mine: true)], thinking: true);
    final ctx = PortfolioContext(
      today: ref.read(clockProvider).today(),
      metrics: ref.read(propertyMetricsProvider),
      ledger: ref.read(ledgerProvider).value ?? const [],
      charges: ref.read(chargesProvider).value ?? const [],
      leases: ref.read(leasesProvider).value ?? const [],
      maintenance: ref.read(maintenanceProvider).value ?? const [],
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    try {
      final a = await ref.read(aiRepositoryProvider).ask(text, ctx);
      state = AskState(messages: [...state.messages, ChatMessage(a.text, mine: false, grounded: a.grounded)]);
    } catch (_) {
      state = AskState(messages: [
        ...state.messages,
        const ChatMessage('I couldn’t reach your portfolio data just now. Please try again.', mine: false, grounded: false),
      ]);
    }
  }
}

final askControllerProvider = NotifierProvider.autoDispose<AskController, AskState>(AskController.new);
