import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type { GymRepository } from '../database/repository/gym.repository';
import type { TrainerGymRepository } from '../database/repository/trainer-gym.repository';
import { buildGymDedupeKey } from './helper/gym-key.helper';
import { GymsService, MAX_TRAINER_GYMS } from './gyms.service';

describe('Сервис залов', () => {
  const gyms = {
    findById: jest.fn(),
    insertIfAbsent: jest.fn(),
    save: jest.fn(),
    suggest: jest.fn(),
  };
  const trainerGyms = {
    attach: jest.fn(),
    detach: jest.fn(),
    exists: jest.fn(),
    countByCoachId: jest.fn(),
    findGymsByCoachId: jest.fn(),
  };
  const service = new GymsService(
    gyms as unknown as GymRepository,
    trainerGyms as unknown as TrainerGymRepository,
  );
  const trainer = { id: 'trainer-1', roles: ['trainer'] };
  const gym = {
    id: 'gym-1',
    name: 'Iron Gym',
    address: 'ул. Ленина, 1',
    city: 'Москва',
    district: null,
    dedupeKey: 'k',
  };

  beforeEach(() => {
    jest.resetAllMocks();
  });

  describe('ключ дедупликации', () => {
    it('игнорирует регистр, ё/е и лишние пробелы', () => {
      expect(
        buildGymDedupeKey({
          name: '  Iron   GYM ',
          address: 'Ул. Ёлочная,  5',
          city: 'москва',
        }),
      ).toBe(
        buildGymDedupeKey({
          name: 'iron gym',
          address: 'ул. Елочная, 5',
          city: 'Москва',
        }),
      );
    });

    it('различает разные адреса', () => {
      expect(
        buildGymDedupeKey({ name: 'A', address: 'x 1', city: 'М' }),
      ).not.toBe(buildGymDedupeKey({ name: 'A', address: 'x 2', city: 'М' }));
    });
  });

  it('создаёт зал по вводу и привязывает к тренеру', async () => {
    gyms.insertIfAbsent.mockResolvedValue(gym);
    trainerGyms.exists.mockResolvedValue(false);
    trainerGyms.countByCoachId.mockResolvedValue(0);

    const result = await service.attach(trainer, {
      name: ' Iron  Gym ',
      address: 'ул. Ленина, 1',
      city: 'Москва',
    });

    expect(gyms.insertIfAbsent).toHaveBeenCalledWith({
      name: 'Iron Gym',
      address: 'ул. Ленина, 1',
      city: 'Москва',
      district: null,
      dedupeKey: 'iron gym|ул. ленина, 1|москва',
    });
    expect(trainerGyms.attach).toHaveBeenCalledWith('trainer-1', 'gym-1');
    expect(result).toEqual({
      id: 'gym-1',
      name: 'Iron Gym',
      address: 'ул. Ленина, 1',
      city: 'Москва',
      district: null,
    });
  });

  it('дописывает район к существующему залу без района', async () => {
    gyms.insertIfAbsent.mockResolvedValue({ ...gym });
    gyms.save.mockImplementation(async (entity: object) => entity);
    trainerGyms.exists.mockResolvedValue(true);

    const result = await service.attach(trainer, {
      name: gym.name,
      address: gym.address,
      city: gym.city,
      district: ' Центр ',
    });

    expect(result.district).toBe('Центр');
    expect(trainerGyms.attach).not.toHaveBeenCalled();
  });

  it('привязывает существующий зал по gymId', async () => {
    gyms.findById.mockResolvedValue(gym);
    trainerGyms.exists.mockResolvedValue(false);
    trainerGyms.countByCoachId.mockResolvedValue(2);

    await service.attach(trainer, { gymId: 'gym-1' });

    expect(gyms.insertIfAbsent).not.toHaveBeenCalled();
    expect(trainerGyms.attach).toHaveBeenCalledWith('trainer-1', 'gym-1');
  });

  it('привязка идемпотентна', async () => {
    gyms.findById.mockResolvedValue(gym);
    trainerGyms.exists.mockResolvedValue(true);

    await service.attach(trainer, { gymId: 'gym-1' });

    expect(trainerGyms.attach).not.toHaveBeenCalled();
  });

  it('404 для неизвестного gymId', async () => {
    gyms.findById.mockResolvedValue(null);

    await expect(
      service.attach(trainer, { gymId: 'missing' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('требует название, адрес и город', async () => {
    await expect(
      service.attach(trainer, { name: 'Gym', address: '  ', city: 'М' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('отклоняет HTML в названии', async () => {
    await expect(
      service.attach(trainer, {
        name: '<b>Gym</b>',
        address: 'a',
        city: 'М',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('ограничивает число залов тренера', async () => {
    gyms.findById.mockResolvedValue(gym);
    trainerGyms.exists.mockResolvedValue(false);
    trainerGyms.countByCoachId.mockResolvedValue(MAX_TRAINER_GYMS);

    await expect(
      service.attach(trainer, { gymId: 'gym-1' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('запрещает ученику управлять залами', async () => {
    await expect(
      service.attach({ id: 's', roles: ['student'] }, { gymId: 'gym-1' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    await expect(
      service.suggest({ id: 's', roles: ['student'] }, { limit: 5 }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('удаляет только свою привязку', async () => {
    trainerGyms.detach.mockResolvedValue(false);

    await expect(service.detach(trainer, 'gym-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('нормализует запрос подсказок', async () => {
    gyms.suggest.mockResolvedValue([gym]);

    const result = await service.suggest(trainer, {
      query: '  iron   gym ',
      city: ' Москва ',
      limit: 5,
    });

    expect(gyms.suggest).toHaveBeenCalledWith({
      query: 'iron gym',
      city: 'Москва',
      limit: 5,
    });
    expect(result).toHaveLength(1);
  });
});
