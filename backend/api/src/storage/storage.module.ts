import { Module } from '@nestjs/common';
import { STORAGE } from './interface';
import { S3StorageService } from './s3-storage.service';

@Module({
  providers: [{ provide: STORAGE, useClass: S3StorageService }],
  exports: [STORAGE],
})
export class StorageModule {}
