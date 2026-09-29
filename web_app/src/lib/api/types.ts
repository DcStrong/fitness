export type AuthUser = {
  id: string;
  email: string;
  roles: string[];
  permissions: string[];
};

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
};

export type Relationship = {
  id: string;
  coachId: string;
  studentId: string;
  roleForViewer: 'coach' | 'student';
  coachEmail?: string | null;
  studentEmail?: string | null;
};

export type ScheduleSlot = {
  id: string;
  coachId: string;
  startsAt: string;
  endsAt: string;
  mode: string;
  status: string;
};

export type SessionItem = {
  id: string;
  coachId: string;
  studentId: string;
  startsAt: string;
  endsAt: string;
  status: string;
  createdBy: string;
  coachEmail?: string | null;
  studentEmail?: string | null;
  finance: SessionFinance;
};

export type Currency = 'RUB';
export type PaymentMethod = 'cash' | 'transfer' | 'card' | 'other';
export type ChargeStatus = 'pending' | 'paid' | 'cancelled';
export type LedgerType = 'income' | 'expense' | 'adjustment';

export type SessionFinance =
  | { status: 'not_tracked' }
  | {
      chargeId: string;
      status: ChargeStatus;
      amountMinor: string;
      currency: Currency;
      earnedAt: string | null;
      paidAt: string | null;
      paymentMethod: PaymentMethod | null;
    };

export type SessionCharge = {
  id: string;
  sessionId: string;
  coachId: string;
  studentId: string;
  amountMinor: string;
  currency: Currency;
  status: ChargeStatus;
  earnedAt: string | null;
  paidAt: string | null;
  paymentMethod: PaymentMethod | null;
  cancelledAt: string | null;
};

export type FinanceSettings = {
  defaultSessionPriceMinor: string;
  currency: Currency;
  updatedAt?: string;
};

export type FinanceSummary = {
  accruedMinor: string;
  receivedMinor: string;
  outstandingMinor: string;
  expensesMinor: string;
  adjustmentsMinor: string;
  netMinor: string;
  currency: Currency;
  counts: {
    completed: number;
    noShowChargeable: number;
    paid: number;
    outstanding: number;
  };
};

export type FinanceDebt = {
  chargeId: string;
  sessionId: string;
  studentId: string;
  studentEmail?: string | null;
  amountMinor: string;
  currency: Currency;
  earnedAt: string;
  sessionStartsAt?: string;
};

export type FinanceLedgerEntry = {
  id: string;
  type: LedgerType;
  amountMinor: string;
  currency: Currency;
  sourceType: 'session_charge' | 'manual';
  sourceId: string | null;
  category: string | null;
  note: string | null;
  occurredAt: string;
  createdAt: string;
  reversesEntryId: string | null;
};

export type SessionHistoryEvent = {
  id: string;
  fromStatus: string;
  toStatus: string;
  note?: string | null;
  actorEmail?: string | null;
  createdAt: string;
};

export type TagItem = {
  id: string;
  name: string;
  creatorId: string;
  creatorEmail?: string | null;
};

export type PlanItem = {
  id: string;
  title: string;
  body: string;
  tags: { id: string; name: string }[];
  ownerCoachEmail?: string | null;
};

export type InvitationCreated = {
  id: string;
  token: string;
  inviteUrl: string;
  deepLink: string;
  expiresAt: string;
};

export type TrainingMode = 'online' | 'offline';

export type OwnerPrivacySettings = {
  isDiscoverable: boolean;
  showRating: boolean;
  showReviews: boolean;
  showReviewerName: boolean;
};

export type OwnerPortfolioItem = {
  id: string;
  title: string;
  description: string | null;
  imageUrl: string | null;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type OwnerProfile = {
  userId: string;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  specialties: string[];
  trainingModes: TrainingMode[];
  privacy: OwnerPrivacySettings;
  portfolio: OwnerPortfolioItem[];
  averageRating: number | null;
  reviewCount: number;
  createdAt: string | null;
  updatedAt: string | null;
};

export type UpdateOwnerProfile = {
  displayName: string;
  avatarUrl?: string | null;
  bio?: string | null;
  city?: string | null;
  specialties?: string[];
  trainingModes?: TrainingMode[];
};

export type SaveOwnerPortfolioItem = {
  title: string;
  description?: string | null;
  imageUrl?: string | null;
};

export type OwnerReceivedReview = {
  id: string;
  sessionId: string;
  coachId: string;
  rating: number;
  text: string | null;
  reviewer: {
    displayName: string;
    avatarUrl: string | null;
  };
  sessionStartsAt: string;
  createdAt: string;
  updatedAt: string;
};

export type PageMeta = {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
};

export type OwnerReceivedReviewsPage = {
  items: OwnerReceivedReview[];
  meta: PageMeta;
  averageRating: number | null;
  reviewCount: number;
};

// Public social contracts are intentionally independent from owner contracts.
// This prevents owner identifiers, privacy flags and timestamps leaking by reuse.
export type PublicPortfolioItem = {
  title: string;
  description: string | null;
  imageUrl: string | null;
  sortOrder: number;
};

export type PublicTrainerProfile = {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  specialties: string[];
  trainingModes: TrainingMode[];
  averageRating?: number | null;
  reviewCount?: number;
  portfolio?: PublicPortfolioItem[];
  isLinked?: boolean;
};

export type PublicTrainerReview = {
  rating: number;
  text: string | null;
  reviewer: {
    displayName: string;
    avatarUrl: string | null;
  };
  sessionStartsAt: string;
  createdAt: string;
  updatedAt: string;
};
