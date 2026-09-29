import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RoleEntity } from '../entity/role.entity';

@Injectable()
export class RoleRepository {
  constructor(
    @InjectRepository(RoleEntity)
    private readonly roles: Repository<RoleEntity>,
  ) {}

  /**
   *
   */
  async findBySlug(slug: string): Promise<RoleEntity | null> {
    return this.roles.findOne({ where: { slug } });
  }
}
