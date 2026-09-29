import { PERMISSIONS, PUBLIC_REGISTER_ROLES } from '../constants';

/**
 *
 */
export type PermissionCode =
  (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

/**
 *
 */
export type PublicRegisterRole = (typeof PUBLIC_REGISTER_ROLES)[number];
