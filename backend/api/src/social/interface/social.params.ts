import type { PreferredContactChannel, TrainingMode } from './social.types';

/**
 *
 */
export interface UpdateProfileParams {
  displayName: string;
  avatarUrl?: string | null;
  bio?: string | null;
  city?: string | null;
  specialties?: string[];
  trainingModes?: TrainingMode[];
  phone?: string | null;
  telegramUsername?: string | null;
  preferredContactChannels?: PreferredContactChannel[];
}

/**
 *
 */
export interface UpdatePrivacyParams {
  isDiscoverable: boolean;
  showRating: boolean;
  showReviews: boolean;
  showReviewerName: boolean;
}

/**
 *
 */
export interface ListTrainersParams {
  page: number;
  limit: number;
  query?: string;
  specialty?: string;
  mode?: TrainingMode;
  city?: string;
  gymId?: string;
  district?: string;
  gymQuery?: string;
}

/**
 *
 */
export interface PaginationParams {
  page: number;
  limit: number;
}

/**
 *
 */
export interface CreatePortfolioItemParams {
  title: string;
  description?: string | null;
  imageUrls?: string[];
  /** Устаревшее одиночное фото, учитывается если `imageUrls` не задан. */
  imageUrl?: string | null;
}

/**
 *
 */
export interface UpdatePortfolioItemParams {
  title: string;
  description?: string | null;
  imageUrls?: string[];
  /** Устаревшее одиночное фото, учитывается если `imageUrls` не задан. */
  imageUrl?: string | null;
}

/**
 *
 */
export interface ReorderPortfolioParams {
  itemIds: string[];
}

/**
 *
 */
export interface SaveReviewParams {
  rating: number;
  text?: string | null;
}
