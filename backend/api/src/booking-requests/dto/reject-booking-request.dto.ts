import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import type { BookingRequestRejectionReason } from '../interface';

export class RejectBookingRequestDto {
  @IsIn(['time_unavailable', 'plans_changed', 'other'])
  reason!: BookingRequestRejectionReason;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
