import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';
import type { BookingRequestStatus } from '../interface';

export class BookingRequestListQueryDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;

  @IsOptional()
  @IsIn(['pending', 'accepted', 'rejected', 'withdrawn', 'expired'])
  status?: BookingRequestStatus;
}
