import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { requireEnv } from '../common/util/require-env.util';
import type { PutObjectParams, StoragePort } from './interface';
import { isUrlUnderBase, readStoragePublicBase } from './util/public-url.util';

/**
 *
 */
interface S3Config {
  client: S3Client;
  bucket: string;
  publicBase: string;
}

/**
 * Реализация `StoragePort` для S3-совместимого хранилища (MinIO).
 * Конфиг читается лениво, поэтому приложение стартует и без S3_* (например, в тестах).
 */
@Injectable()
export class S3StorageService implements StoragePort {
  private config: S3Config | null = null;

  /**
   * Загружает объект в бакет и возвращает публичный URL.
   */
  async put(params: PutObjectParams): Promise<string> {
    const { client, bucket, publicBase } = this.getConfig();
    /* eslint-disable @typescript-eslint/naming-convention -- имена полей задаёт AWS SDK */
    await client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: params.key,
        Body: params.body,
        ContentType: params.contentType,
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );
    /* eslint-enable @typescript-eslint/naming-convention */

    return `${publicBase}/${params.key}`;
  }

  /**
   *
   */
  isOwnUrl(url: string): boolean {
    return isUrlUnderBase(url, readStoragePublicBase());
  }

  /**
   *
   */
  private getConfig(): S3Config {
    if (this.config) {
      return this.config;
    }
    try {
      this.config = {
        client: new S3Client({
          endpoint: requireEnv('S3_ENDPOINT'),
          region: process.env['S3_REGION'] ?? 'us-east-1',
          forcePathStyle: process.env['S3_FORCE_PATH_STYLE'] !== 'false',
          credentials: {
            accessKeyId: requireEnv('S3_ACCESS_KEY'),
            secretAccessKey: requireEnv('S3_SECRET_KEY'),
          },
        }),
        bucket: requireEnv('S3_BUCKET'),
        publicBase: requireEnv('S3_PUBLIC_URL').replace(/\/+$/u, ''),
      };
    } catch {
      throw new ServiceUnavailableException({
        code: 'STORAGE_NOT_CONFIGURED',
        message: 'File storage is not configured',
      });
    }

    return this.config;
  }
}
