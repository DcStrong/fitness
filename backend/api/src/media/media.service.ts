import {
  BadRequestException,
  Inject,
  Injectable,
  PayloadTooLargeException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { STORAGE, type StoragePort } from '../storage/interface';
import { IMAGE_EXTENSIONS, sniffImageMime } from '../storage/util/image-type.util';
import type { UploadedImageModel, UploadImageParams } from './interface';
import { MAX_IMAGE_BYTES } from './media.constants';

@Injectable()
export class MediaService {
  constructor(@Inject(STORAGE) private readonly storage: StoragePort) {}

  /**
   * Проверяет картинку по содержимому (jpeg/png/webp, до 5 МБ) и кладёт в хранилище
   * под ключом `images/<ownerId>/<uuid>.<ext>`; имя файла клиента не используется.
   */
  async uploadImage(params: UploadImageParams): Promise<UploadedImageModel> {
    const { buffer, ownerId } = params;
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
    const url = await this.storage.put({
      key: `images/${ownerId}/${randomUUID()}.${extension}`,
      body: buffer,
      contentType,
    });

    return { url, contentType, size: buffer.length };
  }
}
