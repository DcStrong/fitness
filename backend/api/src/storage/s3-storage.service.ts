import {
  CreateBucketCommand,
  PutBucketPolicyCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  ServiceUnavailableException,
} from '@nestjs/common';
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
export class S3StorageService implements StoragePort, OnApplicationBootstrap {
  private readonly logger = new Logger(S3StorageService.name);

  private config: S3Config | null = null;

  private bucketReady: Promise<void> | null = null;

  /**
   * Пытается подготовить бакет при старте. Ошибка не роняет API: подготовка повторится при первой загрузке.
   */
  onApplicationBootstrap(): void {
    if (!process.env['S3_ENDPOINT']) {
      return;
    }
    this.ensureBucket().catch((error: unknown) => {
      this.logger.warn(`Бакет пока не подготовлен: ${String(error)}`);
    });
  }

  /**
   * Загружает объект в бакет и возвращает публичный URL.
   */
  async put(params: PutObjectParams): Promise<string> {
    const { client, bucket, publicBase } = this.getConfig();
    await this.ensureBucket();
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
   * Создаёт бакет и включает анонимное чтение объектов (запись остаётся только по ключам).
   * Повторный вызов безопасен; при ошибке следующий вызов попробует снова.
   */
  private async ensureBucket(): Promise<void> {
    if (!this.bucketReady) {
      this.bucketReady = this.prepareBucket().catch((error: unknown) => {
        this.bucketReady = null;
        throw error;
      });
    }

    return this.bucketReady;
  }

  /**
   *
   */
  private async prepareBucket(): Promise<void> {
    const { client, bucket } = this.getConfig();
    /* eslint-disable @typescript-eslint/naming-convention -- имена полей задаёт AWS SDK */
    try {
      await client.send(new CreateBucketCommand({ Bucket: bucket }));
    } catch (error) {
      const name = (error as { name?: string; }).name;
      if (name !== 'BucketAlreadyOwnedByYou' && name !== 'BucketAlreadyExists') {
        throw error;
      }
    }
    await client.send(
      new PutBucketPolicyCommand({
        Bucket: bucket,
        Policy: JSON.stringify({
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: '*',
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${bucket}/*`],
            },
          ],
        }),
      }),
    );
    /* eslint-enable @typescript-eslint/naming-convention */
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
