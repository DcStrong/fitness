import { BadRequestException } from '@nestjs/common';
import type { ChatSystemPayload, ChatSystemType } from './interface';

export const CHAT_MESSAGE_MAX_LENGTH = 4000;
export const CHAT_PAGE_DEFAULT_LIMIT = 50;
export const CHAT_PAGE_MAX_LIMIT = 100;

const SYSTEM_TITLES: Record<ChatSystemType, string> = {
  session_booked: 'Новое занятие',
  session_cancelled: 'Занятие отменено',
  session_rescheduled: 'Занятие перенесено',
  occurrence_skipped: 'Занятие пропущено',
  request_accepted: 'Заявка принята',
  request_alternate: 'Предложено другое время',
  request_rejected: 'Заявка отклонена',
};

/**
 * Trims and validates a text message body.
 */
export function normalizeChatBody(raw: string): string {
  const body = raw.trim();
  if (body.length === 0) {
    throw new BadRequestException('Message body must not be empty');
  }
  if (body.length > CHAT_MESSAGE_MAX_LENGTH) {
    throw new BadRequestException(
      `Message body must be at most ${CHAT_MESSAGE_MAX_LENGTH} characters`,
    );
  }

  return body;
}

/**
 * Russian fallback text for clients that do not render `systemType` and for
 * list previews; times stay in the payload because the server has no viewer
 * time zone.
 */
export function systemMessageBody(
  type: ChatSystemType,
  payload: ChatSystemPayload,
): string {
  const title = SYSTEM_TITLES[type];
  const note = payload.note?.trim();

  return note ? `${title}: ${note}` : title;
}
