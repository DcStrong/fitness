import { IsDateString } from 'class-validator';

export class AlternateBookingRequestDto {
  @IsDateString()
  startsAt!: string;
}
