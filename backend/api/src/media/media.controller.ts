import {
  BadRequestException,
  Controller,
  HttpCode,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UploadedImageResponseDto } from './dto/media-response.dto';
import { MAX_IMAGE_BYTES } from './media.constants';
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
    FileInterceptor('file', { limits: { fileSize: MAX_IMAGE_BYTES, files: 1 } }),
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
}
