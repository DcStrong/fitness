import { BadRequestException } from '@nestjs/common';
import sharp from 'sharp';
import { WEBP_QUALITY } from '../media.constants';

/** Защита от «бомб» (маленький файл с гигантским разрешением), пикселей. */
const MAX_INPUT_PIXELS = 50_000_000;

/**
 * Приводит картинку к WebP: поворот по EXIF, вписывание в `maxSide`×`maxSide` без увеличения,
 * метаданные (EXIF, GPS) не сохраняются.
 */
export async function processImageToWebp(buffer: Buffer, maxSide: number): Promise<Buffer> {
  try {
    return await sharp(buffer, { limitInputPixels: MAX_INPUT_PIXELS })
      .rotate()
      .resize({ width: maxSide, height: maxSide, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: WEBP_QUALITY })
      .toBuffer();
  } catch {
    throw new BadRequestException({
      code: 'IMAGE_CORRUPT',
      message: 'Image cannot be decoded',
    });
  }
}
