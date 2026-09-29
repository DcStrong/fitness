import { IsUUID } from 'class-validator';

export class CreateBookingRequestDto {
  @IsUUID()
  scheduleSlotId!: string;
}
