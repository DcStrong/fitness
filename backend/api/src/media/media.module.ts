import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { StorageModule } from '../storage/storage.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';

@Module({
  imports: [DatabaseModule, StorageModule],
  controllers: [MediaController],
  providers: [MediaService],
})
export class MediaModule {}
