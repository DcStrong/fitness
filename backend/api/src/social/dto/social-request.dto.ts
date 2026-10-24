import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { IsMediaUrl } from '../../storage/validator/is-media-url.validator';
import { MAX_PORTFOLIO_ITEMS } from '../social.constants';
import type { PreferredContactChannel, TrainingMode } from '../interface';

export class UpdateProfileDto {
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  displayName!: string;

  @IsOptional()
  @IsMediaUrl()
  @MaxLength(2048)
  avatarUrl?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ArrayUnique()
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  specialties?: string[];

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(['online', 'offline'], { each: true })
  trainingModes?: TrainingMode[];

  @IsOptional()
  @IsString()
  @MaxLength(24)
  phone?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(33)
  telegramUsername?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsIn(['phone', 'telegram', 'email'], { each: true })
  preferredContactChannels?: PreferredContactChannel[];
}

export class UpdatePrivacyDto {
  @IsBoolean()
  isDiscoverable!: boolean;

  @IsBoolean()
  showRating!: boolean;

  @IsBoolean()
  showReviews!: boolean;

  @IsBoolean()
  showReviewerName!: boolean;
}

export class PaginationQueryDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;
}

export class TrainerDiscoveryQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  query?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  specialty?: string;

  @IsOptional()
  @IsIn(['online', 'offline'])
  mode?: TrainingMode;
}

export class SavePortfolioItemDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string | null;

  @IsOptional()
  @IsMediaUrl()
  @MaxLength(2048)
  imageUrl?: string | null;
}

export class ReorderPortfolioDto {
  @IsArray()
  @ArrayMaxSize(MAX_PORTFOLIO_ITEMS)
  @ArrayUnique()
  @IsUUID('4', { each: true })
  itemIds!: string[];
}

export class SaveReviewDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string | null;
}
