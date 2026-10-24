import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { GymEntity } from '../database/entity/gym.entity';
import { GymRepository } from '../database/repository/gym.repository';
import { TrainerGymRepository } from '../database/repository/trainer-gym.repository';
import { buildGymDedupeKey, collapseGymText } from './helper/gym-key.helper';
import type {
  AttachGymParams,
  GymActor,
  GymModel,
  GymSuggestionModel,
  SuggestGymsParams,
} from './interface';

/** Максимум залов в профиле одного тренера. */
export const MAX_TRAINER_GYMS = 10;

@Injectable()
export class GymsService {
  constructor(
    private readonly gyms: GymRepository,
    private readonly trainerGyms: TrainerGymRepository,
  ) {}

  /**
   *
   */
  async listOwn(actor: GymActor): Promise<GymModel[]> {
    this.requireTrainer(actor);

    return (await this.trainerGyms.findGymsByCoachId(actor.id)).map(gym =>
      this.toModel(gym));
  }

  /**
   * Привязывает зал к тренеру: по `gymId` либо по вводу — тогда зал
   * создаётся, если такого (название + адрес + город) ещё нет.
   */
  async attach(actor: GymActor, input: AttachGymParams): Promise<GymModel> {
    this.requireTrainer(actor);
    const gym = await this.resolveGym(input);
    const alreadyAttached = await this.trainerGyms.exists(actor.id, gym.id);

    if (!alreadyAttached) {
      const count = await this.trainerGyms.countByCoachId(actor.id);
      if (count >= MAX_TRAINER_GYMS) {
        throw new ConflictException('Gym limit reached');
      }
      await this.trainerGyms.attach(actor.id, gym.id);
    }

    return this.toModel(gym);
  }

  /**
   *
   */
  async detach(actor: GymActor, gymId: string): Promise<void> {
    this.requireTrainer(actor);
    const detached = await this.trainerGyms.detach(actor.id, gymId);
    if (!detached) {
      throw new NotFoundException('Gym is not attached to the profile');
    }
  }

  /**
   * Подсказки по залам, уже введённым тренерами.
   */
  async suggest(
    actor: GymActor,
    input: SuggestGymsParams,
  ): Promise<GymSuggestionModel[]> {
    this.requireTrainer(actor);
    const query = input.query ? collapseGymText(input.query) : undefined;
    const city = input.city ? collapseGymText(input.city) : undefined;
    const rows = await this.gyms.suggest({
      limit: input.limit,
      ...query ? { query } : {},
      ...city ? { city } : {},
    });

    return rows.map(gym => this.toModel(gym));
  }

  /**
   *
   */
  private async resolveGym(input: AttachGymParams): Promise<GymEntity> {
    if (input.gymId) {
      return this.existingGym(input.gymId);
    }

    return this.findOrCreate(input);
  }

  /**
   *
   */
  private async existingGym(gymId: string): Promise<GymEntity> {
    const gym = await this.gyms.findById(gymId);
    if (!gym) {
      throw new NotFoundException('Gym not found');
    }

    return gym;
  }

  /**
   *
   */
  private async findOrCreate(input: AttachGymParams): Promise<GymEntity> {
    const name = this.requiredText(input.name, 'name');
    const address = this.requiredText(input.address, 'address');
    const city = this.requiredText(input.city, 'city');
    const district = this.optionalText(input.district, 'district');
    const gym = await this.gyms.insertIfAbsent({
      name,
      address,
      city,
      district,
      dedupeKey: buildGymDedupeKey({ name, address, city }),
    });
    if (!gym.district && district) {
      gym.district = district;

      return this.gyms.save(gym);
    }

    return gym;
  }

  /**
   *
   */
  private requiredText(value: string | undefined, field: string): string {
    const normalized = collapseGymText(value ?? '');
    if (!normalized || this.containsHtml(normalized)) {
      throw new BadRequestException(`${field} must be non-empty plain text`);
    }

    return normalized;
  }

  /**
   *
   */
  private optionalText(
    value: string | null | undefined,
    field: string,
  ): string | null {
    const normalized = collapseGymText(value ?? '');
    if (!normalized) {
      return null;
    }
    if (this.containsHtml(normalized)) {
      throw new BadRequestException(`${field} must be plain text`);
    }

    return normalized;
  }

  /**
   *
   */
  private containsHtml(value: string): boolean {
    return /<[^>]+>/u.test(value);
  }

  /**
   *
   */
  private requireTrainer(actor: GymActor): void {
    if (!actor.roles.includes('trainer')) {
      throw new ForbiddenException('Trainer role required');
    }
  }

  /**
   *
   */
  private toModel(gym: GymEntity): GymModel {
    return {
      id: gym.id,
      name: gym.name,
      address: gym.address,
      city: gym.city,
      district: gym.district,
    };
  }
}
