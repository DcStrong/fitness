import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  PayloadTooLargeException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TrainerPortfolioRepository } from '../database/repository/trainer-portfolio.repository';
import { STORAGE, type StoragePort } from '../storage/interface';
import { IMAGE_EXTENSIONS, sniffImageMime } from '../storage/util/image-type.util';
import type { UploadedImageModel, UploadImageParams, UploadPortfolioImagesParams } from './interface';
import { MAX_IMAGE_BYTES, MAX_IMAGES_TOTAL_BYTES, MAX_PORTFOLIO_PHOTOS } from './media.constants';

@Injectable()
export class MediaService {
  constructor(
    @Inject(STORAGE) private readonly storage: StoragePort,
    private readonly portfolio: TrainerPortfolioRepository,
  ) {}

  /**
   * Пакетная загрузка фото портфолио: не больше свободных мест (5 минус уже в портфолио),
   * каждое до 5 МБ, всего до 25 МБ. Проверки идут до первой записи в хранилище.
   */
  async uploadPortfolioImages(
    params: UploadPortfolioImagesParams,
  ): Promise<UploadedImageModel[]> {
    const { buffers, ownerId } = params;
    if (buffers.length === 0) {
      throw new BadRequestException({ code: 'IMAGE_MISSING', message: 'At least one file is required' });
    }
    const free = MAX_PORTFOLIO_PHOTOS - await this.portfolio.countByCoachId(ownerId);
    if (buffers.length > Math.max(free, 0)) {
      throw new ConflictException({
        code: 'PORTFOLIO_LIMIT_REACHED',
        message: `Portfolio is limited to ${MAX_PORTFOLIO_PHOTOS} items, free slots: ${Math.max(free, 0)}`,
      });
    }
    const total = buffers.reduce((sum, buf) => sum + buf.length, 0);
    if (total > MAX_IMAGES_TOTAL_BYTES) {
      throw new PayloadTooLargeException({
        code: 'IMAGES_TOTAL_TOO_LARGE',
        message: `Total size must be at most ${MAX_IMAGES_TOTAL_BYTES} bytes`,
      });
    }
    const checked = buffers.map(buffer => this.validate(buffer));
    const result: UploadedImageModel[] = [];
    for (const item of checked) {
      result.push(await this.store(ownerId, item));
    }

    return result;
  }

  /**
   * Проверяет картинку по содержимому (jpeg/png/webp, до 5 МБ) и кладёт в хранилище
   * под ключом `images/<ownerId>/<uuid>.<ext>`; имя файла клиента не используется.
   */
  async uploadImage(params: UploadImageParams): Promise<UploadedImageModel> {
    return this.store(params.ownerId, this.validate(params.buffer));
  }

  /**
   *
   */
  private validate(buffer: Buffer): { buffer: Buffer; contentType: string; extension: string; } {
    if (buffer.length === 0) {
      throw new BadRequestException({ code: 'IMAGE_EMPTY', message: 'File is empty' });
    }
    if (buffer.length > MAX_IMAGE_BYTES) {
      throw new PayloadTooLargeException({
        code: 'IMAGE_TOO_LARGE',
        message: `Image must be at most ${MAX_IMAGE_BYTES} bytes`,
      });
    }
    const contentType = sniffImageMime(buffer);
    const extension = contentType ? IMAGE_EXTENSIONS.get(contentType) : undefined;
    if (!contentType || !extension) {
      throw new BadRequestException({
        code: 'IMAGE_UNSUPPORTED_TYPE',
        message: 'Only image/jpeg, image/png and image/webp are allowed',
      });
    }

    return { buffer, contentType, extension };
  }

  /**
   *
   */
  private async store(
    ownerId: string,
    image: { buffer: Buffer; contentType: string; extension: string; },
  ): Promise<UploadedImageModel> {
    const url = await this.storage.put({
      key: `images/${ownerId}/${randomUUID()}.${image.extension}`,
      body: image.buffer,
      contentType: image.contentType,
    });

    return { url, contentType: image.contentType, size: image.buffer.length };
  }
}
