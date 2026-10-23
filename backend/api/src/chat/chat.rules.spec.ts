import { BadRequestException } from '@nestjs/common';
import {
  CHAT_MESSAGE_MAX_LENGTH,
  normalizeChatBody,
  systemMessageBody,
} from './chat.rules';

describe('chat.rules', () => {
  it('trims the message body', () => {
    expect(normalizeChatBody('  привет \n')).toBe('привет');
  });

  it('rejects empty and too long bodies', () => {
    expect(() => normalizeChatBody('   ')).toThrow(BadRequestException);
    expect(() =>
      normalizeChatBody('a'.repeat(CHAT_MESSAGE_MAX_LENGTH + 1)),
    ).toThrow(BadRequestException);
    expect(normalizeChatBody('a'.repeat(CHAT_MESSAGE_MAX_LENGTH))).toHaveLength(
      CHAT_MESSAGE_MAX_LENGTH,
    );
  });

  it('builds a Russian fallback body with an optional note', () => {
    expect(systemMessageBody('session_rescheduled', {})).toBe(
      'Занятие перенесено',
    );
    expect(systemMessageBody('request_rejected', { note: ' Уезжаю ' })).toBe(
      'Заявка отклонена: Уезжаю',
    );
  });
});
