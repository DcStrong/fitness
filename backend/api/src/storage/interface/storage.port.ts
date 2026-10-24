export const STORAGE = Symbol('STORAGE');

/**
 *
 */
export interface PutObjectParams {
  key: string;
  body: Buffer;
  contentType: string;
}

/**
 * Порт файлового хранилища. Доменный код зависит только от него,
 * реализация (MinIO/S3 или другая) подменяется в `StorageModule`.
 */
export interface StoragePort {

  /** Сохраняет объект и возвращает его публичный URL. */
  put(params: PutObjectParams): Promise<string>;

  /** Принадлежит ли URL нашему хранилищу. */
  isOwnUrl(url: string): boolean;
}
