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
import { sniffImageMime } from '../storage/util/image-type.util';
import { processImageToWebp } from './helper/image-processor.helper';
import type { UploadedImageModel, UploadImageParams, UploadPortfolioImagesParams } from './interface';
import {
  AVATAR_IMAGE_MAX_SIDE,
  MAX_IMAGE_BYTES,
  MAX_IMAGES_TOTAL_BYTES,
  MAX_PORTFOLIO_PHOTOS,
  PORTFOLIO_IMAGE_MAX_SIDE,
} from './media.constants';

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
    buffers.forEach(buffer => this.validate(buffer));
    const processed: Buffer[] = [];
    for (const buffer of buffers) {
      processed.push(await processImageToWebp(buffer, PORTFOLIO_IMAGE_MAX_SIDE));
    }
    const result: UploadedImageModel[] = [];
    for (const item of processed) {
      result.push(await this.store(ownerId, item));
    }

    return result;
  }

  /**
   * Аватар: проверка по содержимому (jpeg/png/webp, до 5 МБ), конвертация в WebP до 512 px
   * и сохранение под ключом `images/<ownerId>/<uuid>.webp`; имя файла клиента не используется.
   */
  async uploadImage(params: UploadImageParams): Promise<UploadedImageModel> {
    this.validate(params.buffer);
    const webp = await processImageToWebp(params.buffer, AVATAR_IMAGE_MAX_SIDE);

    return this.store(params.ownerId, webp);
  }

  /**
   * Проверяет размер и тип по сигнатуре (не по заголовку клиента).
   */
  private validate(buffer: Buffer): void {
    if (buffer.length === 0) {
      throw new BadRequestException({ code: 'IMAGE_EMPTY', message: 'File is empty' });
    }
    if (buffer.length > MAX_IMAGE_BYTES) {
      throw new PayloadTooLargeException({
        code: 'IMAGE_TOO_LARGE',
        message: `Image must be at most ${MAX_IMAGE_BYTES} bytes`,
      });
    }
    if (!sniffImageMime(buffer)) {
      throw new BadRequestException({
        code: 'IMAGE_UNSUPPORTED_TYPE',
        message: 'Only image/jpeg, image/png and image/webp are allowed',
      });
    }
  }

  /**
   *
   */
  private async store(ownerId: string, webp: Buffer): Promise<UploadedImageModel> {
    const contentType = 'image/webp';
    const url = await this.storage.put({
      key: `images/${ownerId}/${randomUUID()}.webp`,
      body: webp,
      contentType,
    });

    return { url, contentType, size: webp.length };
  }
}
