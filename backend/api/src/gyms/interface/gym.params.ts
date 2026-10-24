/**
 * Привязка зала: существующий по `gymId` либо ввод названия и адреса.
 */
export interface AttachGymParams {
  gymId?: string;
  name?: string;
  address?: string;
  city?: string;
  district?: string | null;
}

/**
 *
 */
export interface SuggestGymsParams {
  query?: string;
  city?: string;
  limit: number;
}
