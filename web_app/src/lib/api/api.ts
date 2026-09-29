import { apiRequest } from './client';
import type {
  AuthResponse,
  AuthUser,
  Currency,
  FinanceDebt,
  FinanceLedgerEntry,
  FinanceSettings,
  FinanceSummary,
  InvitationCreated,
  LedgerType,
  OwnerPortfolioItem,
  OwnerPrivacySettings,
  OwnerProfile,
  OwnerReceivedReviewsPage,
  PaymentMethod,
  PlanItem,
  Relationship,
  SaveOwnerPortfolioItem,
  ScheduleSlot,
  SessionCharge,
  SessionHistoryEvent,
  SessionItem,
  TagItem,
  UpdateOwnerProfile,
} from './types';

export const api = {
  login(email: string, password: string) {
    return apiRequest<AuthResponse>('/auth/login', {
      method: 'POST',
      body: { email, password },
      auth: false,
    });
  },
  logout(refreshToken: string) {
    return apiRequest<{ ok: boolean }>('/auth/logout', {
      method: 'POST',
      body: { refreshToken },
      auth: false,
    });
  },
  me() {
    return apiRequest<AuthUser>('/users/me');
  },
  relationships() {
    return apiRequest<Relationship[]>('/relationships/me');
  },
  listSlots() {
    return apiRequest<ScheduleSlot[]>('/schedule/slots');
  },
  createSlot(data: { startsAt: string; endsAt: string; mode?: string }) {
    return apiRequest<ScheduleSlot>('/schedule/slots', {
      method: 'POST',
      body: data,
    });
  },
  deleteSlot(id: string) {
    return apiRequest<void>(`/schedule/slots/${id}`, { method: 'DELETE' });
  },
  listSessions() {
    return apiRequest<SessionItem[]>('/sessions');
  },
  completeSession(id: string) {
    return apiRequest<SessionItem>(`/sessions/${id}/complete`, {
      method: 'POST',
    });
  },
  cancelSession(id: string, note?: string) {
    return apiRequest<SessionItem>(`/sessions/${id}/cancel`, {
      method: 'POST',
      body: note ? { note } : {},
    });
  },
  noShowSession(id: string, charge: boolean) {
    return apiRequest<SessionItem>(`/sessions/${id}/no-show`, {
      method: 'POST',
      body: { charge },
    });
  },
  financeSettings() {
    return apiRequest<FinanceSettings>('/finance/settings');
  },
  updateFinanceSettings(data: {
    defaultSessionPriceMinor: string;
    currency: Currency;
  }) {
    return apiRequest<FinanceSettings>('/finance/settings', {
      method: 'PUT',
      body: data,
    });
  },
  financeSummary(from: string, to: string) {
    const query = new URLSearchParams({ from, to });
    return apiRequest<FinanceSummary>(`/finance/summary?${query}`);
  },
  financeLedger(
    from: string,
    to: string,
    type?: LedgerType,
    studentId?: string,
  ) {
    const query = new URLSearchParams({ from, to });
    if (type) query.set('type', type);
    if (studentId) query.set('studentId', studentId);
    return apiRequest<FinanceLedgerEntry[]>(`/finance/ledger?${query}`);
  },
  financeDebts(studentId?: string) {
    const query = new URLSearchParams();
    if (studentId) query.set('studentId', studentId);
    const suffix = query.size ? `?${query}` : '';
    return apiRequest<FinanceDebt[]>(`/finance/debts${suffix}`);
  },
  markChargePaid(
    chargeId: string,
    data: { paymentMethod: PaymentMethod; paidAt?: string },
  ) {
    return apiRequest<SessionCharge>(
      `/finance/charges/${chargeId}/mark-paid`,
      {
        method: 'POST',
        body: data,
      },
    );
  },
  createExpense(data: {
    amountMinor: string;
    category?: string;
    note?: string;
    occurredAt?: string;
  }) {
    return apiRequest<FinanceLedgerEntry>('/finance/expenses', {
      method: 'POST',
      body: data,
    });
  },
  reverseLedgerEntry(id: string) {
    return apiRequest<FinanceLedgerEntry>(`/finance/ledger/${id}/reverse`, {
      method: 'POST',
      body: {},
    });
  },
  sessionHistory(id: string) {
    return apiRequest<SessionHistoryEvent[]>(`/sessions/${id}/history`);
  },
  listTags() {
    return apiRequest<TagItem[]>('/tags');
  },
  createTag(name: string) {
    return apiRequest<TagItem>('/tags', { method: 'POST', body: { name } });
  },
  deleteTag(id: string) {
    return apiRequest<void>(`/tags/${id}`, { method: 'DELETE' });
  },
  assignTag(tagId: string, userId: string) {
    return apiRequest(`/tags/${tagId}/users`, {
      method: 'POST',
      body: { userId },
    });
  },
  listPlans() {
    return apiRequest<PlanItem[]>('/plans');
  },
  createPlan(data: { title: string; body?: string; tagIds?: string[] }) {
    return apiRequest<PlanItem>('/plans', { method: 'POST', body: data });
  },
  updatePlan(
    id: string,
    data: { title?: string; body?: string; tagIds?: string[] },
  ) {
    return apiRequest<PlanItem>(`/plans/${id}`, {
      method: 'PATCH',
      body: data,
    });
  },
  getPlan(id: string) {
    return apiRequest<PlanItem>(`/plans/${id}`);
  },
  createInvitation() {
    return apiRequest<InvitationCreated>('/invitations', { method: 'POST' });
  },
  ownerProfile() {
    return apiRequest<OwnerProfile>('/profiles/me');
  },
  updateOwnerProfile(data: UpdateOwnerProfile) {
    return apiRequest<OwnerProfile>('/profiles/me', {
      method: 'PUT',
      body: data,
    });
  },
  updateOwnerPrivacy(data: OwnerPrivacySettings) {
    return apiRequest<OwnerProfile>('/profiles/me/privacy', {
      method: 'PUT',
      body: data,
    });
  },
  createOwnerPortfolioItem(data: SaveOwnerPortfolioItem) {
    return apiRequest<OwnerPortfolioItem>('/profiles/me/portfolio', {
      method: 'POST',
      body: data,
    });
  },
  updateOwnerPortfolioItem(id: string, data: SaveOwnerPortfolioItem) {
    return apiRequest<OwnerPortfolioItem>(`/profiles/me/portfolio/${id}`, {
      method: 'PUT',
      body: data,
    });
  },
  reorderOwnerPortfolio(itemIds: string[]) {
    return apiRequest<OwnerPortfolioItem[]>('/profiles/me/portfolio/reorder', {
      method: 'PUT',
      body: { itemIds },
    });
  },
  deleteOwnerPortfolioItem(id: string) {
    return apiRequest<void>(`/profiles/me/portfolio/${id}`, {
      method: 'DELETE',
    });
  },
  ownerReceivedReviews(page = 1, limit = 20) {
    const query = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });
    return apiRequest<OwnerReceivedReviewsPage>(
      `/profiles/me/reviews?${query}`,
    );
  },
};
