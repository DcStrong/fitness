/**
 *
 */
export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

/**
 *
 */
export interface AuthProfile {
  id: string;
  email: string;
  roles: string[];
  permissions: string[];
}

/**
 *
 */
export interface AuthResponse extends AuthTokens {
  user: AuthProfile;
}

/**
 *
 */
export interface LogoutReturns {
  success: true;
}
