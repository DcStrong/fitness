import { Injectable } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import type { UserMeReturns } from './interface/user-me.returns';

@Injectable()
export class UsersService {
  constructor(private readonly authService: AuthService) {}

  /**
   *
   */
  async getMe(userId: string): Promise<UserMeReturns> {
    return this.authService.getProfile(userId);
  }
}
