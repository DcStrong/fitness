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
  displayName: string | null;
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
