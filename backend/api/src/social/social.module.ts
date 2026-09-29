import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import {
  ProfilesController,
  ReviewsController,
  SessionReviewsController,
  TrainersController,
} from './social.controller';
import { SocialService } from './social.service';

@Module({
  imports: [DatabaseModule],
  controllers: [
    ProfilesController,
    TrainersController,
    SessionReviewsController,
    ReviewsController,
  ],
  providers: [SocialService],
  exports: [SocialService],
})
export class SocialModule {}
