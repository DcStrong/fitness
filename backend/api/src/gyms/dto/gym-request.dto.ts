import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

export class AttachGymDto {
  /** Выбор зала из подсказок; тогда остальные поля не нужны. */
  @IsOptional()
  @IsUUID('4')
  gymId?: string;

  @ValidateIf((dto: AttachGymDto) => !dto.gymId)
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  @ValidateIf((dto: AttachGymDto) => !dto.gymId)
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  address?: string;

  @ValidateIf((dto: AttachGymDto) => !dto.gymId)
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  city?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  district?: string | null;
}

export class GymSuggestionsQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  query?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(20)
  limit = 10;
}
