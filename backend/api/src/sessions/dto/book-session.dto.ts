import {
  IsDateString,
  IsIn,
  IsOptional,
  IsUUID,
  Matches,
  ValidateIf,
} from 'class-validator';

/**
 * XOR: either `scheduleSlotId` or (`startsAt` + `endsAt`).
 * Coach book-at-time also requires `studentId`.
 */
export class BookSessionDto {
  @ValidateIf(o => o.startsAt == null && o.endsAt == null)
  @IsUUID()
  scheduleSlotId?: string;

  @ValidateIf(o => o.scheduleSlotId == null)
  @IsDateString()
  startsAt?: string;

  @ValidateIf(o => o.scheduleSlotId == null)
  @IsDateString()
  endsAt?: string;

  @ValidateIf(o => o.scheduleSlotId == null)
  @IsOptional()
  @IsIn(['online', 'offline'])
  mode?: 'online' | 'offline';

  /** Required when coach books for a student (always for book-at-time). */
  @IsOptional()
  @IsUUID()
  studentId?: string;

  /** Trainer-only one-session override, decimal string in minor units. */
  @IsOptional()
  @Matches(/^[1-9]\d*$/, {
    message: 'priceMinor must be a positive integer string',
  })
  priceMinor?: string;
}
