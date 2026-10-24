import { GymResponseDto } from '../../gyms/dto/gym-response.dto';
import type {
  OwnerProfileModel,
  PortfolioItemModel,
  PublicTrainerProfile,
  PublicTrainerSummary,
  ReviewModel,
  TrainerDiscoveryPage,
} from '../interface';

export class PortfolioItemResponseDto {
  id: string;

  title: string;

  description: string | null;

  imageUrl: string | null;

  sortOrder: number;

  createdAt: Date;

  updatedAt: Date;

  constructor(item: PortfolioItemModel) {
    this.id = item.id;
    this.title = item.title;
    this.description = item.description;
    this.imageUrl = item.imageUrl;
    this.sortOrder = item.sortOrder;
    this.createdAt = item.createdAt;
    this.updatedAt = item.updatedAt;
  }
}

export class PublicPortfolioItemResponseDto {
  title: string;

  description: string | null;

  imageUrl: string | null;

  sortOrder: number;

  constructor(item: PortfolioItemModel) {
    this.title = item.title;
    this.description = item.description;
    this.imageUrl = item.imageUrl;
    this.sortOrder = item.sortOrder;
  }
}

export class OwnerProfileResponseDto {
  userId: string;

  displayName: string | null;

  avatarUrl: string | null;

  bio: string | null;

  city: string | null;

  specialties: string[];

  trainingModes: string[];

  phone: string | null;

  telegramUsername: string | null;

  preferredContactChannels: OwnerProfileModel['preferredContactChannels'];

  email: string;

  privacy: OwnerProfileModel['privacy'];

  portfolio: PortfolioItemResponseDto[];

  gyms: GymResponseDto[];

  averageRating: number | null;

  reviewCount: number;

  createdAt: Date | null;

  updatedAt: Date | null;

  constructor(profile: OwnerProfileModel) {
    this.userId = profile.userId;
    this.displayName = profile.displayName;
    this.avatarUrl = profile.avatarUrl;
    this.bio = profile.bio;
    this.city = profile.city;
    this.specialties = profile.specialties;
    this.trainingModes = profile.trainingModes;
    this.phone = profile.phone;
    this.telegramUsername = profile.telegramUsername;
    this.preferredContactChannels = profile.preferredContactChannels;
    this.email = profile.email;
    this.privacy = profile.privacy;
    this.portfolio = profile.portfolio.map(
      item => new PortfolioItemResponseDto(item),
    );
    this.averageRating = profile.averageRating;
    this.gyms = profile.gyms.map(gym => new GymResponseDto(gym));
    this.reviewCount = profile.reviewCount;
    this.createdAt = profile.createdAt;
    this.updatedAt = profile.updatedAt;
  }
}

export class PublicTrainerResponseDto {
  id: string;

  displayName: string;

  avatarUrl: string | null;

  bio: string | null;

  city: string | null;

  specialties: string[];

  trainingModes: string[];

  gyms: GymResponseDto[];

  averageRating?: number | null;

  reviewCount?: number;

  portfolio?: PublicPortfolioItemResponseDto[];

  isLinked?: boolean;

  constructor(profile: PublicTrainerSummary | PublicTrainerProfile) {
    this.id = profile.id;
    this.displayName = profile.displayName;
    this.avatarUrl = profile.avatarUrl;
    this.bio = profile.bio;
    this.city = profile.city;
    this.specialties = profile.specialties;
    this.trainingModes = profile.trainingModes;
    this.gyms = profile.gyms.map(gym => new GymResponseDto(gym));
    if (profile.averageRating !== undefined) {
      this.averageRating = profile.averageRating;
    }
    if (profile.reviewCount !== undefined) {
      this.reviewCount = profile.reviewCount;
    }
    if ('portfolio' in profile) {
      this.portfolio = profile.portfolio.map(
        item => new PublicPortfolioItemResponseDto(item),
      );
    }
    if ('isLinked' in profile && profile.isLinked !== undefined) {
      this.isLinked = profile.isLinked;
    }
  }
}

export class TrainerDiscoveryResponseDto {
  items: PublicTrainerResponseDto[];

  meta: TrainerDiscoveryPage['meta'];

  constructor(page: TrainerDiscoveryPage) {
    this.items = page.items.map(item => new PublicTrainerResponseDto(item));
    this.meta = page.meta;
  }
}

export class ReviewResponseDto {
  id: string;

  sessionId: string;

  coachId: string;

  rating: number;

  text: string | null;

  reviewer: ReviewModel['reviewer'];

  sessionStartsAt: Date;

  createdAt: Date;

  updatedAt: Date;

  constructor(review: ReviewModel) {
    this.id = review.id;
    this.sessionId = review.sessionId;
    this.coachId = review.coachId;
    this.rating = review.rating;
    this.text = review.text;
    this.reviewer = review.reviewer;
    this.sessionStartsAt = review.sessionStartsAt;
    this.createdAt = review.createdAt;
    this.updatedAt = review.updatedAt;
  }
}

export class PublicReviewResponseDto {
  rating: number;

  text: string | null;

  reviewer: ReviewModel['reviewer'];

  sessionStartsAt: Date;

  createdAt: Date;

  updatedAt: Date;

  constructor(review: ReviewModel) {
    this.rating = review.rating;
    this.text = review.text;
    this.reviewer = review.reviewer;
    this.sessionStartsAt = review.sessionStartsAt;
    this.createdAt = review.createdAt;
    this.updatedAt = review.updatedAt;
  }
}
