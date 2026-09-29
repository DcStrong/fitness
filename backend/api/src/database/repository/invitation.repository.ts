import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InvitationEntity } from '../entity/invitation.entity';

@Injectable()
export class InvitationRepository {
  constructor(
    @InjectRepository(InvitationEntity)
    private readonly invitations: Repository<InvitationEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<InvitationEntity>): InvitationEntity {
    return this.invitations.create(data);
  }

  /**
   *
   */
  async save(entity: InvitationEntity): Promise<InvitationEntity> {
    return this.invitations.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<InvitationEntity | null> {
    return this.invitations.findOne({ where: { id } });
  }

  /**
   *
   */
  async findByTokenHash(tokenHash: string): Promise<InvitationEntity | null> {
    return this.invitations.findOne({ where: { tokenHash } });
  }

  /**
   *
   */
  async findByCoachId(coachId: string): Promise<InvitationEntity[]> {
    return this.invitations.find({
      where: { coachId },
      order: { createdAt: 'DESC' },
    });
  }
}
