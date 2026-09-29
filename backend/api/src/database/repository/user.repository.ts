import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { RoleEntity } from '../entity/role.entity';
import { UserEntity } from '../entity/user.entity';

@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  /**
   *
   */
  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.users.findOne({ where: { email } });
  }

  /**
   *
   */
  async findById(id: string): Promise<UserEntity | null> {
    return this.users.findOne({ where: { id } });
  }

  async findByIds(ids: string[]): Promise<UserEntity[]> {
    if (!ids.length) {
      return [];
    }
    return this.users.find({ where: { id: In(ids) } });
  }

  /**
   *
   */
  async findByIdWithAccess(id: string): Promise<UserEntity | null> {
    return this.users.findOne({
      where: { id },
      relations: {
        roles: {
          permissions: true,
        },
      },
    });
  }

  /**
   *
   */
  async createWithRole(
    email: string,
    passwordHash: string,
    role: RoleEntity,
  ): Promise<UserEntity> {
    const user = this.users.create({
      email,
      passwordHash,
      roles: [role],
    });

    return this.users.save(user);
  }
}
