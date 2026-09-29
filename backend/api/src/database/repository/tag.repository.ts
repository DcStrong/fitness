import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { TagEntity } from '../entity/tag.entity';

@Injectable()
export class TagRepository {
  constructor(
    @InjectRepository(TagEntity)
    private readonly tags: Repository<TagEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<TagEntity>): TagEntity {
    return this.tags.create(data);
  }

  /**
   *
   */
  async save(entity: TagEntity): Promise<TagEntity> {
    return this.tags.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<TagEntity | null> {
    return this.tags.findOne({
      where: { id },
      relations: { creator: true },
    });
  }

  /**
   *
   */
  async findByCreator(creatorId: string): Promise<TagEntity[]> {
    return this.tags.find({
      where: { creatorId },
      relations: { creator: true },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   *
   */
  async findByCreatorAndName(
    creatorId: string,
    name: string,
  ): Promise<TagEntity | null> {
    return this.tags.findOne({ where: { creatorId, name } });
  }

  /**
   *
   */
  async findByIdsForCreator(
    creatorId: string,
    ids: string[],
  ): Promise<TagEntity[]> {
    if (ids.length === 0) {
return Promise.resolve([]);
}

    return this.tags.find({
      where: { creatorId, id: In(ids) },
    });
  }

  /**
   *
   */
  async deleteById(id: string): Promise<void> {
    await this.tags.delete({ id });
  }
}
