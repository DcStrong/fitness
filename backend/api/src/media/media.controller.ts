import {
  BadRequestException,
  Controller,
  HttpCode,
  Post,
  Req,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UploadedImagesResponseDto } from './dto/media-batch-response.dto';
import { UploadedImageResponseDto } from './dto/media-response.dto';
import { MAX_IMAGE_BYTES, MAX_PORTFOLIO_PHOTOS, MULTER_SLACK_BYTES } from './media.constants';
import { MediaService } from './media.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('media')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MediaController {
  constructor(private readonly media: MediaService) {}

  /**
   * Загрузка картинки (multipart, поле `file`) для аватара или фото портфолио.
   * Возвращённый `url` передаётся в `avatarUrl` / `imageUrl`.
   */
  @Post('images')
  @HttpCode(201)
  @RequirePermissions(PERMISSIONS.PROFILES_UPDATE_OWN)
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_IMAGE_BYTES + MULTER_SLACK_BYTES, files: 1 } }),
  )
  async uploadImage(
    @Req() req: RequestWithUser,
    @UploadedFile() file: Express.Multer.File | undefined,
  ): Promise<UploadedImageResponseDto> {
    if (!file) {
      throw new BadRequestException({
        code: 'IMAGE_MISSING',
        message: 'Multipart field "file" is required',
      });
    }

    return new UploadedImageResponseDto(
      await this.media.uploadImage({ ownerId: req.user.id, buffer: file.buffer }),
    );
  }

  /**
   * Пакетная загрузка фото портфолио (multipart, поле `files`, до 5 штук, каждое до 5 МБ,
   * всего до 25 МБ, с учётом свободных мест в портфолио). Возвращает `items` в порядке файлов.
   */
  @Post('portfolio-images')
  @HttpCode(201)
  @RequirePermissions(PERMISSIONS.PORTFOLIO_MANAGE_OWN)
  @UseInterceptors(
    FilesInterceptor('files', MAX_PORTFOLIO_PHOTOS, {
      limits: { fileSize: MAX_IMAGE_BYTES + MULTER_SLACK_BYTES, files: MAX_PORTFOLIO_PHOTOS },
    }),
  )
  async uploadPortfolioImages(
    @Req() req: RequestWithUser,
    @UploadedFiles() files: Express.Multer.File[] | undefined,
  ): Promise<UploadedImagesResponseDto> {
    return new UploadedImagesResponseDto(
      await this.media.uploadPortfolioImages({
        ownerId: req.user.id,
        buffers: (files ?? []).map(file => file.buffer),
      }),
    );
  }
}
