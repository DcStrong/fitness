import {
  IsEmail,
  IsIn,
  IsString,
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

  @IsIn([...PUBLIC_REGISTER_ROLES])
  role!: PublicRegisterRole;
}
