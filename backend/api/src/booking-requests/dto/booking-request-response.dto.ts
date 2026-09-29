import type {
  BookingRequestModel,
  BookingRequestSlotSummary,
} from '../interface';

export class BookingRequestResponseDto implements BookingRequestModel {
  id: string;

  coachId: string;

  studentId: string;

  scheduleSlotId: string;

  status: BookingRequestModel['status'];

  quotedPriceMinor: BookingRequestModel['quotedPriceMinor'];

  quotedCurrency: BookingRequestModel['quotedCurrency'];

  expiresAt: string;

  resolvedBy: string | null;

  resolvedAt: string | null;

  rejectionReason: BookingRequestModel['rejectionReason'];

  rejectionComment: string | null;

  resolution: BookingRequestModel['resolution'];

  resolvedScheduleSlotId: string | null;

  sessionId: string | null;

  requestedSlot: BookingRequestSlotSummary;

  resolvedSlot: BookingRequestSlotSummary | null;

  counterpart: BookingRequestModel['counterpart'];

  createdAt: string;

  updatedAt: string;

  constructor(request: BookingRequestModel) {
    this.id = request.id;
    this.coachId = request.coachId;
    this.studentId = request.studentId;
    this.scheduleSlotId = request.scheduleSlotId;
    this.status = request.status;
    this.quotedPriceMinor = request.quotedPriceMinor;
    this.quotedCurrency = request.quotedCurrency;
    this.expiresAt = request.expiresAt;
    this.resolvedBy = request.resolvedBy;
    this.resolvedAt = request.resolvedAt;
    this.rejectionReason = request.rejectionReason;
    this.rejectionComment = request.rejectionComment;
    this.resolution = request.resolution;
    this.resolvedScheduleSlotId = request.resolvedScheduleSlotId;
    this.sessionId = request.sessionId;
    this.requestedSlot = request.requestedSlot;
    this.resolvedSlot = request.resolvedSlot;
    this.counterpart = request.counterpart;
    this.createdAt = request.createdAt;
    this.updatedAt = request.updatedAt;
  }
}
