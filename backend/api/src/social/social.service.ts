import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { QueryFailedError } from 'typeorm';
import { MAX_PORTFOLIO_ITEMS } from './social.constants';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionReviewRepository } from '../database/repository/session-review.repository';
import { TrainerPortfolioRepository } from '../database/repository/trainer-portfolio.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { UserRepository } from '../database/repository/user.repository';
import type { SessionReviewEntity } from '../database/entity/session-review.entity';
import type { TrainerPortfolioItemEntity } from '../database/entity/trainer-portfolio-item.entity';
import type { UserProfileEntity } from '../database/entity/user-profile.entity';
import type {
  CreatePortfolioItemParams,
  EligibleReviewSession,
  ListTrainersParams,
  LinkedContactsModel,
  OwnerProfileModel,
  OwnerReviewPage,
  PaginationParams,
  PortfolioItemModel,
  PublicTrainerProfile,
  ReorderPortfolioParams,
  ReviewModel,
  ReviewPage,
  SaveReviewParams,
  SocialActor,
  TrainerDiscoveryPage,
  UpdatePrivacyParams,
  UpdateProfileParams,
  UpdatePortfolioItemParams,
} from './interface';

@Injectable()
export class SocialService {
  constructor(
    private readonly profiles: UserProfileRepository,
    private readonly portfolio: TrainerPortfolioRepository,
    private readonly reviews: SessionReviewRepository,
    private readonly sessions: SessionRepository,
    private readonly links: CoachStudentLinkRepository,
    private readonly users: UserRepository,
  ) {}

  /**
   *
   */
  async getOwnProfile(actor: SocialActor): Promise<OwnerProfileModel> {
    const profile = await this.profiles.findByUserId(actor.id);
    const items = this.isTrainer(actor)? await this.portfolio.findByCoachId(actor.id): [];
    const rating = this.isTrainer(actor)? await this.reviews.ratingForCoach(actor.id): { averageRating: null, reviewCount: 0 };
    const email =
      actor.email ?? (await this.users.findById(actor.id))?.email ?? '';

    return this.toOwnerProfile(actor.id, email, profile, items, rating);
  }

  /**
   *
   */
  async updateOwnProfile(
    actor: SocialActor,
    input: UpdateProfileParams,
  ): Promise<OwnerProfileModel> {
    this.assertSupportedProfileFields(actor, input);
    const profile =
      await this.profiles.findByUserId(actor.id) ??
      this.profiles.create({ userId: actor.id });
    const displayName = this.requiredText(input.displayName, 'displayName');
    const specialties = this.normalizeSpecialties(input.specialties ?? []);
    profile.displayName = displayName;
    profile.avatarUrl = input.avatarUrl ?? null;
    profile.bio = this.optionalText(input.bio, 'bio');
    profile.city = this.optionalText(input.city, 'city');
    profile.specialties = specialties;
    profile.trainingModes = input.trainingModes ?? [];
    this.applyContacts(profile, input);
    await this.profiles.save(profile);

    return this.getOwnProfile(actor);
  }

  /**
   *
   */
  async getLinkedContacts(
    actor: SocialActor,
    targetUserId: string,
  ): Promise<LinkedContactsModel> {
    const link =
      await this.links.findByPair(actor.id, targetUserId) ??
      await this.links.findByPair(targetUserId, actor.id);
    if (!link) {
      throw new ForbiddenException('Users are not actively linked');
    }
    const user = await this.users.findById(targetUserId);
    if (!user) {
throw new NotFoundException('User not found');
}
    const profile = await this.profiles.findByUserId(targetUserId);
    const preferred = profile ? profile.preferredContactChannels : [];
    let phone: string | null = null;
    let telegramUsername: string | null = null;
    if (profile && preferred.includes('phone')) {
      phone = profile.phone;
    }
    if (profile && preferred.includes('telegram')) {
      telegramUsername = profile.telegramUsername;
    }

    return {
      userId: targetUserId,
      phone,
      telegramUsername,
      email: user.email,
      preferredContactChannels: preferred.includes('email')? preferred: [...preferred, 'email'],
    };
  }

  /**
   *
   */
  async updateOwnPrivacy(
    actor: SocialActor,
    input: UpdatePrivacyParams,
  ): Promise<OwnerProfileModel> {
    if (input.isDiscoverable && !this.isTrainer(actor)) {
      throw new BadRequestException('Only trainers can be discoverable');
    }
    const profile =
      await this.profiles.findByUserId(actor.id) ??
      this.profiles.create({ userId: actor.id });
    if (input.isDiscoverable && !profile.displayName) {
      throw new BadRequestException(
        'A display name is required before publication',
      );
    }
    profile.isDiscoverable = input.isDiscoverable;
    profile.showRating = input.showRating;
    profile.showReviews = input.showReviews;
    profile.showReviewerName = input.showReviewerName;
    await this.profiles.save(profile);

    return this.getOwnProfile(actor);
  }

  /**
   *
   */
  async listTrainers(
    input: ListTrainersParams,
  ): Promise<TrainerDiscoveryPage> {
    const records = await this.profiles.listDiscoverable({
      ...input,
      ...input.query ? { query: this.normalizeSearch(input.query) } : {},
      ...input.specialty? { specialty: this.normalizeSearch(input.specialty).toLowerCase() }: {},
    });

    return {
      items: records.items.map(({ profile, averageRating, reviewCount }) => ({
        id: profile.userId,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        bio: profile.bio,
        city: profile.city,
        specialties: profile.specialties,
        trainingModes: profile.trainingModes,
        ...profile.showRating ? { averageRating, reviewCount } : {},
      })),
      meta: this.pageMeta(input, records.total),
    };
  }

  /**
   *
   */
  async getTrainer(
    actor: SocialActor,
    trainerId: string,
  ): Promise<PublicTrainerProfile> {
    const profile = await this.profiles.findDiscoverableTrainer(trainerId);
    if (!profile?.displayName) {
      throw new NotFoundException('Trainer not found');
    }
    const [items, rating] = await Promise.all([
      this.portfolio.findByCoachId(trainerId),
      this.reviews.ratingForCoach(trainerId),
    ]);
    const base: PublicTrainerProfile = {
      id: trainerId,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      city: profile.city,
      specialties: profile.specialties,
      trainingModes: profile.trainingModes,
      portfolio: items.map(item => this.toPortfolio(item)),
    };
    if (profile.showRating) {
      base.averageRating = rating.averageRating;
      base.reviewCount = rating.reviewCount;
    }
    if (actor.roles.includes('student')) {
      base.isLinked = Boolean(
        await this.links.findByPair(trainerId, actor.id),
      );
    }

    return base;
  }

  /**
   *
   */
  async createPortfolioItem(
    actor: SocialActor,
    input: CreatePortfolioItemParams,
  ): Promise<PortfolioItemModel> {
    this.requireTrainer(actor);
    const count = await this.portfolio.countByCoachId(actor.id);
    if (count >= MAX_PORTFOLIO_ITEMS) {
      throw new ConflictException({
        code: 'PORTFOLIO_LIMIT_REACHED',
        message: `Portfolio is limited to ${MAX_PORTFOLIO_ITEMS} items`,
      });
    }
    const item = this.portfolio.create({
      coachId: actor.id,
      title: this.requiredText(input.title, 'title'),
      description: this.optionalText(input.description, 'description'),
      imageUrl: input.imageUrl ?? null,
      sortOrder: count,
    });

    return this.toPortfolio(await this.portfolio.save(item));
  }

  /**
   *
   */
  async updatePortfolioItem(
    actor: SocialActor,
    itemId: string,
    input: UpdatePortfolioItemParams,
  ): Promise<PortfolioItemModel> {
    this.requireTrainer(actor);
    const item = await this.ownedPortfolioItem(actor.id, itemId);
    item.title = this.requiredText(input.title, 'title');
    item.description = this.optionalText(input.description, 'description');
    item.imageUrl = input.imageUrl ?? null;

    return this.toPortfolio(await this.portfolio.save(item));
  }

  /**
   *
   */
  async reorderPortfolio(
    actor: SocialActor,
    input: ReorderPortfolioParams,
  ): Promise<PortfolioItemModel[]> {
    this.requireTrainer(actor);
    const existing = await this.portfolio.findByCoachId(actor.id);
    if (
      existing.length !== input.itemIds.length ||
      existing.some(item => !input.itemIds.includes(item.id))
    ) {
      throw new BadRequestException(
        'itemIds must contain the complete own portfolio',
      );
    }
    const positions = new Map(input.itemIds.map((id, index) => [id, index]));
    for (const item of existing) {
      item.sortOrder = positions.get(item.id) ?? item.sortOrder;
    }
    const saved = await this.portfolio.saveMany(existing);

    return saved
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map(item => this.toPortfolio(item));
  }

  /**
   *
   */
  async deletePortfolioItem(
    actor: SocialActor,
    itemId: string,
  ): Promise<void> {
    this.requireTrainer(actor);
    const item = await this.ownedPortfolioItem(actor.id, itemId);
    await this.portfolio.deleteById(item.id);
  }

  /**
   *
   */
  async createReview(
    actor: SocialActor,
    sessionId: string,
    input: SaveReviewParams,
  ): Promise<ReviewModel> {
    const session = await this.sessions.findById(sessionId);
    if (!session || session.studentId !== actor.id) {
      throw new ForbiddenException('Session is not owned by this student');
    }
    if (session.status !== 'completed') {
      throw new ConflictException('Only completed sessions can be reviewed');
    }
    const review = this.reviews.create({
      sessionId,
      coachId: session.coachId,
      studentId: actor.id,
      rating: input.rating,
      text: this.optionalText(input.text, 'text'),
    });
    try {
      const saved = await this.reviews.save(review);
      saved.session = session;

      return this.toReview(saved, await this.reviewer(saved.studentId));
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw new ConflictException('Session already has a review');
      }
      throw error;
    }
  }

  /**
   *
   */
  async updateOwnReview(
    actor: SocialActor,
    reviewId: string,
    input: SaveReviewParams,
  ): Promise<ReviewModel> {
    const review = await this.reviews.findById(reviewId);
    if (!review || review.studentId !== actor.id) {
      throw new ForbiddenException('Review is not owned by this student');
    }
    review.rating = input.rating;
    review.text = this.optionalText(input.text, 'text');

    return this.toReview(
      await this.reviews.save(review),
      await this.reviewer(actor.id),
    );
  }

  /**
   *
   */
  async listEligible(actor: SocialActor): Promise<EligibleReviewSession[]> {
    if (!actor.roles.includes('student')) {
      throw new ForbiddenException('Only students have review eligibility');
    }

    return this.reviews.findEligible(actor.id);
  }

  /**
   *
   */
  async listMine(actor: SocialActor): Promise<ReviewModel[]> {
    const rows = await this.reviews.findByStudentId(actor.id);
    const reviewer = await this.reviewer(actor.id);

    return rows.map(row => this.toReview(row, reviewer));
  }

  /**
   *
   */
  async listTrainerReviews(
    trainerId: string,
    params: PaginationParams,
  ): Promise<ReviewPage> {
    const profile = await this.profiles.findDiscoverableTrainer(trainerId);
    if (!profile) {
      throw new NotFoundException('Trainer not found');
    }
    if (!profile.showReviews) {
      return { items: [], meta: this.pageMeta(params, 0) };
    }

    return this.reviewPage(trainerId, params);
  }

  /**
   *
   */
  async listReceivedReviews(
    actor: SocialActor,
    params: PaginationParams,
  ): Promise<OwnerReviewPage> {
    this.requireTrainer(actor);
    const [page, rating] = await Promise.all([
      this.reviewPage(actor.id, params),
      this.reviews.ratingForCoach(actor.id),
    ]);

    return { ...page, ...rating };
  }

  /**
   *
   */
  private async reviewPage(
    trainerId: string,
    params: PaginationParams,
  ): Promise<ReviewPage> {
    const [rows, total] = await this.reviews.findByCoachId(trainerId, params);
    const items = await Promise.all(
      rows.map(async row =>
        this.toReview(row, await this.reviewer(row.studentId))),
    );

    return { items, meta: this.pageMeta(params, total) };
  }

  /**
   *
   */
  private async reviewer(
    studentId: string,
  ): Promise<{ displayName: string; avatarUrl: string | null; }> {
    const profile = await this.profiles.findByUserId(studentId);
    if (!profile?.showReviewerName || !profile.displayName) {
      return { displayName: 'Ученик', avatarUrl: null };
    }

    return {
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    };
  }

  /**
   *
   */
  private toReview(
    review: SessionReviewEntity,
    reviewer: { displayName: string; avatarUrl: string | null; },
  ): ReviewModel {
    return {
      id: review.id,
      sessionId: review.sessionId,
      coachId: review.coachId,
      rating: review.rating,
      text: review.text,
      reviewer,
      sessionStartsAt: review.session.startsAt,
      createdAt: review.createdAt,
      updatedAt: review.updatedAt,
    };
  }

  /**
   *
   */
  private toOwnerProfile(
    userId: string,
    email: string,
    profile: UserProfileEntity | null,
    items: TrainerPortfolioItemEntity[],
    rating: { averageRating: number | null; reviewCount: number; },
  ): OwnerProfileModel {
    if (!profile) {
      return {
        userId,
        displayName: null,
        avatarUrl: null,
        bio: null,
        city: null,
        specialties: [],
        trainingModes: [],
        phone: null,
        telegramUsername: null,
        preferredContactChannels: [],
        email,
        privacy: {
          isDiscoverable: false,
          showRating: true,
          showReviews: true,
          showReviewerName: false,
        },
        portfolio: items.map(item => this.toPortfolio(item)),
        averageRating: rating.averageRating,
        reviewCount: rating.reviewCount,
        createdAt: null,
        updatedAt: null,
      };
    }

    return {
      userId,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      city: profile.city,
      specialties: profile.specialties,
      trainingModes: profile.trainingModes,
      phone: profile.phone,
      telegramUsername: profile.telegramUsername,
      preferredContactChannels: profile.preferredContactChannels,
      email,
      privacy: {
        isDiscoverable: profile.isDiscoverable,
        showRating: profile.showRating,
        showReviews: profile.showReviews,
        showReviewerName: profile.showReviewerName,
      },
      portfolio: items.map(item => this.toPortfolio(item)),
      averageRating: rating.averageRating,
      reviewCount: rating.reviewCount,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    };
  }

  /**
   *
   */
  private assertSupportedProfileFields(
    actor: SocialActor,
    input: UpdateProfileParams,
  ): void {
    if (this.isTrainer(actor)) {
      return;
    }
    const hasTrainerFields =
      Boolean(input.city?.trim()) ||
      Boolean(input.specialties?.length) ||
      Boolean(input.trainingModes?.length);
    if (hasTrainerFields) {
      throw new BadRequestException(
        'Trainer profile fields are not supported for students',
      );
    }
  }

  /**
   *
   */
  private applyContacts(
    profile: UserProfileEntity,
    input: UpdateProfileParams,
  ): void {
    profile.phone = this.normalizePhone(input.phone);
    profile.telegramUsername = this.normalizeTelegram(input.telegramUsername);
    profile.preferredContactChannels = input.preferredContactChannels ?? [];
    if (profile.preferredContactChannels.includes('phone') && !profile.phone) {
      throw new BadRequestException('Phone is required for preferred channel');
    }
    if (
      profile.preferredContactChannels.includes('telegram') &&
      !profile.telegramUsername
    ) {
      throw new BadRequestException(
        'Telegram username is required for preferred channel',
      );
    }
  }

  /**
   *
   */
  private normalizePhone(value: string | null | undefined): string | null {
    if (!value) {
return null;
}
    const normalized = value.replace(/[\s()-]/gu, '');
    if (!/^\+[1-9]\d{7,14}$/u.test(normalized)) {
      throw new BadRequestException('phone must use international format');
    }

    return normalized;
  }

  /**
   *
   */
  private normalizeTelegram(value: string | null | undefined): string | null {
    if (!value) {
return null;
}
    const normalized = value.trim().replace(/^@/u, '');
    if (!/^[A-Za-z][A-Za-z0-9_]{4,31}$/u.test(normalized)) {
      throw new BadRequestException('Invalid Telegram username');
    }

    return normalized;
  }

  /**
   *
   */
  private toPortfolio(item: TrainerPortfolioItemEntity): PortfolioItemModel {
    return {
      id: item.id,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl,
      sortOrder: item.sortOrder,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  /**
   *
   */
  private async ownedPortfolioItem(
    coachId: string,
    itemId: string,
  ): Promise<TrainerPortfolioItemEntity> {
    const item = await this.portfolio.findById(itemId);
    if (!item || item.coachId !== coachId) {
      throw new NotFoundException('Portfolio item not found');
    }

    return item;
  }

  /**
   *
   */
  private requiredText(value: string, field: string): string {
    const normalized = this.normalizeSearch(value);
    if (!normalized || this.containsHtml(normalized)) {
      throw new BadRequestException(`${field} must be non-empty plain text`);
    }

    return normalized;
  }

  /**
   *
   */
  private optionalText(
    value: string | null | undefined,
    field: string,
  ): string | null {
    if (value === null || value === undefined) {
return null;
}
    const normalized = this.normalizeSearch(value);
    if (!normalized) {
return null;
}
    if (this.containsHtml(normalized)) {
      throw new BadRequestException(`${field} must be plain text`);
    }

    return normalized;
  }

  /**
   *
   */
  private normalizeSpecialties(values: string[]): string[] {
    const normalized = values.map(value =>
      this.requiredText(value, 'specialty').toLowerCase());
    if (new Set(normalized).size !== normalized.length) {
      throw new BadRequestException('specialties must be unique');
    }

    return normalized;
  }

  /**
   *
   */
  private normalizeSearch(value: string): string {
    return value.trim().replace(/\s+/gu, ' ');
  }

  /**
   *
   */
  private containsHtml(value: string): boolean {
    return /<[^>]+>/u.test(value);
  }

  /**
   *
   */
  private pageMeta(
    params: PaginationParams,
    total: number,
  ): { page: number; limit: number; total: number; totalPages: number; } {
    return {
      page: params.page,
      limit: params.limit,
      total,
      totalPages: Math.ceil(total / params.limit),
    };
  }

  /**
   *
   */
  private isTrainer(actor: SocialActor): boolean {
    return actor.roles.includes('trainer');
  }

  /**
   *
   */
  private requireTrainer(actor: SocialActor): void {
    if (!this.isTrainer(actor)) {
      throw new ForbiddenException('Trainer role required');
    }
  }

  /**
   *
   */
  private isUniqueViolation(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'driverError' in error &&
      (error as QueryFailedError & { driverError?: { code?: string; }; })
        .driverError?.code === '23505'
    );
  }
}
