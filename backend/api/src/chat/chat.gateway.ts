import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  type OnGatewayConnection,
  type OnGatewayInit,
  WebSocketGateway,
} from '@nestjs/websockets';
import type { Namespace, Socket } from 'socket.io';
import { PERMISSIONS } from '../access-control/constants';
import type { JwtPayload } from '../auth/interface/jwt-payload.interface';
import { ChatEventsService, chatUserRoom } from './chat-events.service';

/**
 * Server → client delivery channel. Writes go through REST; a socket only
 * joins its user room and receives `message.created` / `conversation.read`.
 */
@WebSocketGateway({ namespace: '/chat', cors: { origin: true, credentials: true } })
export class ChatGateway implements OnGatewayInit, OnGatewayConnection {
  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly events: ChatEventsService,
  ) {}

  /**
   *
   */
  afterInit(namespace: Namespace): void {
    this.events.attach(namespace);
  }

  /**
   *
   */
  async handleConnection(client: Socket): Promise<void> {
    const token = extractToken(client);
    if (!token) {
      client.disconnect(true);

      return;
    }
    let payload: JwtPayload & { exp?: number; };
    try {
      payload = await this.jwt.verifyAsync<JwtPayload & { exp?: number; }>(token);
    } catch {
      client.disconnect(true);

      return;
    }
    if (!(payload.permissions ?? []).includes(PERMISSIONS.CHAT_READ_OWN)) {
      client.disconnect(true);

      return;
    }

    client.data.userId = payload.sub;
    await client.join(chatUserRoom(payload.sub));

    /*
     * Drop the socket when the access token expires; the app reconnects
     * with a refreshed token and catches up through REST.
     */
    if (payload.exp !== undefined) {
      const ttl = (payload.exp * 1000) - Date.now();
      const timer = setTimeout(() => client.disconnect(true), Math.max(ttl, 0));
      timer.unref?.();
      client.once('disconnect', () => clearTimeout(timer));
    }
    this.logger.debug(`chat socket connected for ${payload.sub}`);
  }
}

/**
 * Token from socket.io `auth.token`, falling back to a Bearer header for
 * clients that cannot set handshake auth.
 */
function extractToken(client: Socket): string | null {
  const auth = client.handshake.auth as { token?: unknown; } | undefined;
  if (typeof auth?.token === 'string' && auth.token.length > 0) {
    return auth.token;
  }
  const header = client.handshake.headers.authorization;
  if (typeof header === 'string' && header.startsWith('Bearer ')) {
    return header.slice('Bearer '.length);
  }

  return null;
}
