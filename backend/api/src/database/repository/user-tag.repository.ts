import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { UserTagEntity } from '../entity/user-tag.entity';

@Injectable()
export class UserTagRepository {
  constructor(
    @InjectRepository(UserTagEntity)
    private readonly userTags: Repository<UserTagEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<UserTagEntity>): UserTagEntity {
    return this.userTags.create(data);
  }

  /**
   *
   */
  async save(entity: UserTagEntity): Promise<UserTagEntity> {
    return this.userTags.save(entity);
  }

  /**
   *
   */
  async findByUserAndTag(
    userId: string,
    tagId: string,
  ): Promise<UserTagEntity | null> {
    return this.userTags.findOne({ where: { userId, tagId } });
  }

  /**
   *
   */
  async findByTagId(tagId: string): Promise<UserTagEntity[]> {
    return this.userTags.find({
      where: { tagId },
      relations: { user: true },
      order: { assignedAt: 'ASC' },
    });
  }

  /**
   *
   */
  async findUserIdsByTagIds(tagIds: string[]): Promise<string[]> {
    if (tagIds.length === 0) {
      return [];
    }
    const rows = await this.userTags.find({
      where: { tagId: In(tagIds) },
    });

    return [...new Set(rows.map(row => row.userId))];
  }

  /**
   *
   */
  async findTagsForUser(userId: string): Promise<UserTagEntity[]> {
    return this.userTags.find({
      where: { userId },
      relations: { tag: { creator: true } },
      order: { assignedAt: 'DESC' },
    });
  }

  /**
   *
   */
  async deleteByUserAndTag(userId: string, tagId: string): Promise<void> {
    await this.userTags.delete({ userId, tagId });
  }
}
