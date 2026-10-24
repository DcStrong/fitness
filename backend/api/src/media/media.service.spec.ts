import { BadRequestException, PayloadTooLargeException } from '@nestjs/common';
import type { StoragePort } from '../storage/interface';
import { MAX_IMAGE_BYTES } from './media.constants';
import { MediaService } from './media.service';

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]);
const WEBP = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBPVP8 ')]);

describe('MediaService', () => {
  const storage = {
    put: jest.fn(async ({ key }: { key: string; }) => `https://cdn.test/${key}`),
    isOwnUrl: jest.fn(),
  };
  const service = new MediaService(storage as unknown as StoragePort);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it.each([
    ['image/jpeg', 'jpg', JPEG],
    ['image/png', 'png', PNG],
    ['image/webp', 'webp', WEBP],
  ])('сохраняет %s под ключом владельца', async (contentType, ext, buffer) => {
    const result = await service.uploadImage({ ownerId: 'user-1', buffer });

    expect(result.contentType).toBe(contentType);
    expect(result.size).toBe(buffer.length);
    expect(result.url).toMatch(
      new RegExp(`^https://cdn.test/images/user-1/[0-9a-f-]{36}\\.${ext}$`, 'u'),
    );
    expect(storage.put).toHaveBeenCalledWith(
      expect.objectContaining({ contentType, body: buffer }),
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
});
