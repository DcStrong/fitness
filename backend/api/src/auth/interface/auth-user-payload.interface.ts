/**
 *
 */
export interface AuthUserPayload {
  id: string;
  email: string;
  roles: string[];
  permissions: string[];
}

/**
 *
 */
export interface AuthenticatedRequest {
  user?: AuthUserPayload;
}
