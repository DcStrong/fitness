import { BadRequestException, ConflictException, PayloadTooLargeException } from '@nestjs/common';
import type { TrainerPortfolioRepository } from '../database/repository/trainer-portfolio.repository';
import type { StoragePort } from '../storage/interface';
import { MAX_IMAGE_BYTES, MAX_IMAGES_TOTAL_BYTES } from './media.constants';
import { MediaService } from './media.service';

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]);
const WEBP = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBPVP8 ')]);

jest.mock('./helper/image-processor.helper', () => ({
  processImageToWebp: jest.fn(async (buf: Buffer) => Buffer.from(`webp:${buf.length}`)),
}));

describe('MediaService', () => {
  const storage = {
    put: jest.fn(async ({ key }: { key: string; }) => `https://cdn.test/${key}`),
    isOwnUrl: jest.fn(),
  };
  const portfolio = { countPhotosByCoachId: jest.fn() };
  const service = new MediaService(
    storage as unknown as StoragePort,
    portfolio as unknown as TrainerPortfolioRepository,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    portfolio.countPhotosByCoachId.mockResolvedValue(0);
  });

  it.each([
    ['image/jpeg', JPEG],
    ['image/png', PNG],
    ['image/webp', WEBP],
  ])('конвертирует %s в webp и сохраняет под ключом владельца', async (_type, buffer) => {
    const result = await service.uploadImage({ ownerId: 'user-1', buffer });

    expect(result.contentType).toBe('image/webp');
    expect(result.url).toMatch(/^https:\/\/cdn\.test\/images\/user-1\/[0-9a-f-]{36}\.webp$/u);
    expect(storage.put).toHaveBeenCalledWith(
      expect.objectContaining({ contentType: 'image/webp', body: Buffer.from(`webp:${buffer.length}`) }),
    );
  });

  it('отклоняет файл с неподдерживаемой сигнатурой', async () => {
    await expect(
      service.uploadImage({ ownerId: 'user-1', buffer: Buffer.from('<svg></svg>') }),
    ).rejects.toMatchObject({ response: { code: 'IMAGE_UNSUPPORTED_TYPE' } });
    expect(storage.put).not.toHaveBeenCalled();
  });

  it('отклоняет пустой файл', async () => {
    await expect(
      service.uploadImage({ ownerId: 'user-1', buffer: Buffer.alloc(0) }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('отклоняет файл больше лимита', async () => {
    const big = Buffer.concat([JPEG, Buffer.alloc(MAX_IMAGE_BYTES)]);

    await expect(
      service.uploadImage({ ownerId: 'user-1', buffer: big }),
    ).rejects.toBeInstanceOf(PayloadTooLargeException);
  });

  describe('uploadPortfolioImages', () => {
    /**
     *
     */
    function sized(size: number): Buffer {
      return Buffer.concat([JPEG, Buffer.alloc(size - JPEG.length)]);
    }

    it('принимает большой и маленький файл', async () => {
      const result = await service.uploadPortfolioImages({
        ownerId: 'u',
        buffers: [sized(MAX_IMAGE_BYTES), sized(1000)],
      });

      expect(result).toHaveLength(2);
    });

    it('принимает 5 файлов по 5 МБ (ровно 25 МБ)', async () => {
      const result = await service.uploadPortfolioImages({
        ownerId: 'u',
        buffers: Array.from({ length: 5 }, () => sized(MAX_IMAGE_BYTES)),
      });

      expect(result).toHaveLength(5);
      expect(5 * MAX_IMAGE_BYTES).toBe(MAX_IMAGES_TOTAL_BYTES);
    });

    it('отклоняет 6 файлов', async () => {
      await expect(
        service.uploadPortfolioImages({ ownerId: 'u', buffers: Array.from({ length: 6 }, () => JPEG) }),
      ).rejects.toMatchObject({ response: { code: 'PORTFOLIO_LIMIT_REACHED' } });
      expect(storage.put).not.toHaveBeenCalled();
    });

    it('учитывает уже имеющиеся фото портфолио', async () => {
      portfolio.countPhotosByCoachId.mockResolvedValue(4);

      await expect(
        service.uploadPortfolioImages({ ownerId: 'u', buffers: [JPEG, JPEG] }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('отклоняет файл больше 5 МБ кодом IMAGE_TOO_LARGE и ничего не сохраняет', async () => {
      await expect(
        service.uploadPortfolioImages({ ownerId: 'u', buffers: [JPEG, sized(MAX_IMAGE_BYTES + 1)] }),
      ).rejects.toMatchObject({ response: { code: 'IMAGE_TOO_LARGE' } });
      expect(storage.put).not.toHaveBeenCalled();
    });

    it('отклоняет сумму больше 25 МБ кодом IMAGES_TOTAL_TOO_LARGE', async () => {
      // число файлов обходим моком свободных мест, чтобы сработала именно проверка суммы
      portfolio.countPhotosByCoachId.mockResolvedValue(-1);
      const buffers = Array.from({ length: 6 }, () => sized(MAX_IMAGE_BYTES));

      await expect(
        service.uploadPortfolioImages({ ownerId: 'u', buffers }),
      ).rejects.toMatchObject({ response: { code: 'IMAGES_TOTAL_TOO_LARGE' } });
    });
  });
});
