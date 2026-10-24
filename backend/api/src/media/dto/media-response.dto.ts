import type { UploadedImageModel } from '../interface';

export class UploadedImageResponseDto {
  url: string;

  contentType: string;

  size: number;

  constructor(model: UploadedImageModel) {
    this.url = model.url;
    this.contentType = model.contentType;
    this.size = model.size;
  }
}
