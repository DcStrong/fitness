import type { UploadedImageModel } from '../interface';
import { UploadedImageResponseDto } from './media-response.dto';

export class UploadedImagesResponseDto {
  items: UploadedImageResponseDto[];

  constructor(models: UploadedImageModel[]) {
    this.items = models.map(model => new UploadedImageResponseDto(model));
  }
}
