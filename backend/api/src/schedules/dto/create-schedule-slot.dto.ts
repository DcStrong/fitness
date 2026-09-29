import { IsDateString, IsIn, IsOptional } from 'class-validator';

export class CreateScheduleSlotDto {
  @IsDateString()
  startsAt!: string;

  @IsDateString()
  endsAt!: string;

  @IsOptional()
  @IsIn(['online', 'offline'])
  mode?: 'online' | 'offline';
}
