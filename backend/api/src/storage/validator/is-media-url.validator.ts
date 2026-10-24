import { registerDecorator, type ValidationOptions } from 'class-validator';
import { isUrlUnderBase, readStoragePublicBase } from '../util/public-url.util';

/**
 * URL картинки: любая https-ссылка либо адрес нашего хранилища (в dev он может быть http).
 */
export function isMediaUrl(value: unknown): boolean {
  if (typeof value !== 'string') {
    return false;
  }
  if (isUrlUnderBase(value, readStoragePublicBase())) {
    return true;
  }
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

/**
 *
 */
// eslint-disable-next-line @typescript-eslint/naming-convention -- декоратор class-validator, PascalCase по соглашению
export function IsMediaUrl(options?: ValidationOptions): PropertyDecorator {
  return (target, propertyName) => {
    registerDecorator({
      name: 'isMediaUrl',
      target: target.constructor,
      propertyName: propertyName as string,
      options: {
        message: `${String(propertyName)} must be an https URL or a storage URL`,
        ...options,
      },
      validator: { validate: isMediaUrl },
    });
  };
}
