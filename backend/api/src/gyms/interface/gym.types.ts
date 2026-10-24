/**
 *
 */
export interface GymModel {
  id: string;
  name: string;
  address: string;
  city: string;
  district: string | null;
}

/**
 *
 */
export type GymSuggestionModel = GymModel;

/**
 *
 */
export interface GymActor {
  id: string;
  roles: string[];
}
