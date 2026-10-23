import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { PUBLIC_REGISTER_ROLES } from '../../access-control/constants';
import type { PublicRegisterRole } from '../../access-control/interface/permission-code.type';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value)
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  displayName?: string;

  @IsIn([...PUBLIC_REGISTER_ROLES])
  role!: PublicRegisterRole;
}
