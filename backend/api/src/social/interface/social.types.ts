import type { GymModel } from '../../gyms/interface';

/**
 *
 */
export type TrainingMode = 'online' | 'offline';

/**
 *
 */
export type PreferredContactChannel = 'phone' | 'telegram' | 'email';

/**
 *
 */
export interface SocialActor {
  id: string;
  email?: string;
  roles: string[];
}

/**
 *
 */
export interface PrivacySettings {
  isDiscoverable: boolean;
  showRating: boolean;
  showReviews: boolean;
  showReviewerName: boolean;
}

/**
 *
 */
export interface PortfolioItemModel {
  id: string;
  title: string;
  description: string | null;
  imageUrl: string | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 *
 */
export interface OwnerProfileModel {
  userId: string;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  specialties: string[];
  trainingModes: TrainingMode[];
  phone: string | null;
  telegramUsername: string | null;
  preferredContactChannels: PreferredContactChannel[];
  email: string;
  privacy: PrivacySettings;
  portfolio: PortfolioItemModel[];
  gyms: GymModel[];
  averageRating: number | null;
  reviewCount: number;
  createdAt: Date | null;
  updatedAt: Date | null;
}

/**
 *
 */
export interface LinkedContactsModel {
  userId: string;
  phone: string | null;
  telegramUsername: string | null;
  email: string;
  preferredContactChannels: PreferredContactChannel[];
}

/**
 *
 */
export interface PublicTrainerSummary {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  specialties: string[];
  trainingModes: TrainingMode[];
  gyms: GymModel[];
  averageRating?: number | null;
  reviewCount?: number;
}

/**
 *
 */
export interface PublicTrainerProfile extends PublicTrainerSummary {
  portfolio: PortfolioItemModel[];
  isLinked?: boolean;
}

/**
 *
 */
export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

/**
 *
 */
export interface TrainerDiscoveryPage {
  items: PublicTrainerSummary[];
  meta: PageMeta;
}

/**
 *
 */
export interface TrainerDiscoveryRecord {
  profile: {
    userId: string;
    displayName: string;
    avatarUrl: string | null;
    bio: string | null;
    city: string | null;
    specialties: string[];
    trainingModes: TrainingMode[];
    showRating: boolean;
  };
  averageRating: number | null;
  reviewCount: number;
}

/**
 *
 */
export interface TrainerDiscoveryRecords {
  items: TrainerDiscoveryRecord[];
  total: number;
}

/**
 *
 */
export interface RatingAggregate {
  averageRating: number | null;
  reviewCount: number;
}

/**
 *
 */
export interface ReviewerProjection {
  displayName: string;
  avatarUrl: string | null;
}

/**
 *
 */
export interface ReviewModel {
  id: string;
  sessionId: string;
  coachId: string;
  rating: number;
  text: string | null;
  reviewer: ReviewerProjection;
  sessionStartsAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 *
 */
export interface OwnReviewModel extends ReviewModel {
  studentId: string;
}

/**
 *
 */
export interface ReviewPage {
  items: ReviewModel[];
  meta: PageMeta;
}

/**
 *
 */
export interface OwnerReviewPage extends ReviewPage {
  averageRating: number | null;
  reviewCount: number;
}

/**
 *
 */
export interface EligibleReviewSession {
  sessionId: string;
  coachId: string;
  coachDisplayName: string | null;
  startsAt: Date;
  endsAt: Date;
  mode: TrainingMode;
}
