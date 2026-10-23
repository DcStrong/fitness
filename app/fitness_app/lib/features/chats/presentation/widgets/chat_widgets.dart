import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/person_name_email.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/chat_models.dart';
import '../chat_format.dart';

/// Unread counter: filled primary pill (board «Чаты»).
class ChatCountBadge extends StatelessWidget {
  const ChatCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Conversation row: avatar, name + time, preview + unread badge.
class ChatConversationRow extends StatelessWidget {
  const ChatConversationRow({
    required this.conversation,
    required this.myUserId,
    required this.now,
    required this.onTap,
    super.key,
  });

  final ChatConversation conversation;
  final String myUserId;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final counterpart = conversation.counterpart;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final mine = last != null && last.senderId == myUserId;
    final name = personPrimaryLabel(
      displayName: counterpart.displayName,
      email: counterpart.email,
    );
    final time = conversation.lastMessageAt ?? last?.createdAt;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            FyAvatar(
              displayName: counterpart.displayName,
              email: counterpart.email,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatChatListTime(time, now: now),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (mine)
                                const TextSpan(
                                  text: 'Вы: ',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              TextSpan(
                                text: last == null
                                    ? 'Нет сообщений'
                                    : chatPreview(last),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        ChatCountBadge(count: unread),
                      ],
                    ],
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

/// Centered day pill between messages.
class ChatDayDivider extends StatelessWidget {
  const ChatDayDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.sunken,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Text bubble: own on the right in primary, counterpart's outlined on the left.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.mine,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.delivery == ChatDeliveryState.failed;
    final sending = message.delivery == ChatDeliveryState.sending;
    final fg = mine ? AppColors.onPrimary : AppColors.textPrimary;
    final metaColor = mine ? AppColors.onPrimaryMuted : AppColors.textTertiary;
    const big = Radius.circular(20);
    const small = Radius.circular(6);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.surface,
        border: mine ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.only(
          topLeft: big,
          topRight: big,
          bottomLeft: mine ? big : small,
          bottomRight: mine ? small : big,
        ),
      ),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            message.body,
            style: TextStyle(
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sending) ...[
                Icon(Icons.schedule_rounded, size: 12, color: metaColor),
                const SizedBox(width: 4),
              ],
              Text(
                formatChatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  color: metaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: failed
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Opacity(opacity: 0.7, child: bubble),
                TextButton.icon(
                  key: Key('chat-retry-${message.clientId}'),
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.error_outline_rounded, size: 16),
                  label: const Text('Не отправлено · повторить'),
                ),
              ],
            )
          : bubble,
    );
  }
}

/// Session event card (board «Переписка»: time tile + title + status chip).
class ChatSystemCard extends StatelessWidget {
  const ChatSystemCard({required this.message, this.onOpenSession, super.key});

  final ChatMessage message;
  final VoidCallback? onOpenSession;

  @override
  Widget build(BuildContext context) {
    final payload = message.payload;
    final startsAt = payload?.startsAt;
    final note = payload?.note?.trim();
    final subtitle = [
      if (startsAt != null) formatChatSessionDate(startsAt),
      if (startsAt == null && payload?.localDate != null)
        formatChatSessionDate(DateTime.parse(payload!.localDate!)),
      if (payload?.previousStartsAt != null)
        'было ${formatChatTime(payload!.previousStartsAt!)}',
      if (note != null && note.isNotEmpty && note != 'recurring_cancelled')
        note,
    ].join(' · ');
    final status = switch (message.systemType) {
      ChatSystemType.sessionCancelled ||
      ChatSystemType.occurrenceSkipped ||
      ChatSystemType.requestRejected => FyStatus.cancelled,
      _ => FyStatus.confirmed,
    };
    final statusLabel = switch (message.systemType) {
      ChatSystemType.sessionCancelled => 'Отменено',
      ChatSystemType.occurrenceSkipped => 'Пропуск',
      ChatSystemType.requestRejected => 'Отклонено',
      _ => 'Подтверждено',
    };
    final canOpen = payload?.sessionId != null && onOpenSession != null;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('chat-system-${message.id}'),
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: canOpen ? onOpenSession : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sunken,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: startsAt != null
                    ? Text(
                        formatChatTime(startsAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      )
                    : const Icon(
                        Icons.event_busy_rounded,
                        color: AppColors.textTertiary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatSystemTitle(message),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FyStatusChip(status: status, label: statusLabel),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message input with the screen's single filled button (send).
class ChatComposer extends StatefulWidget {
  const ChatComposer({required this.onSend, this.enabled = true, super.key});

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && _controller.text.trim().isNotEmpty;
    const radius = BorderRadius.all(Radius.circular(AppRadii.control));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat-input'),
              controller: _controller,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, height: 20 / 16),
              decoration: const InputDecoration(
                hintText: 'Сообщение',
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Отправить',
            child: Material(
              color: canSend ? AppColors.primary : AppColors.sunken,
              borderRadius: radius,
              child: InkWell(
                key: const Key('chat-send'),
                borderRadius: radius,
                onTap: canSend ? _submit : null,
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.send_rounded,
                    color: canSend
                        ? AppColors.onPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
