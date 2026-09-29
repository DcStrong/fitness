import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { PERMISSIONS_KEY } from './permissions.decorator';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  /**
   *
   */
  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!required || required.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<
      Request & { user?: AuthUserPayload; }
    >();
    const userPermissions = request.user?.permissions ?? [];
    const missing = required.filter(code => !userPermissions.includes(code));

    if (missing.length > 0) {
      throw new ForbiddenException('Missing required permissions');
    }

    return true;
  }
}
