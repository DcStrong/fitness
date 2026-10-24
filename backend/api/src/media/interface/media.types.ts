/**
 *
 */
export interface UploadedImageModel {
  url: string;
  contentType: string;
  size: number;
}

/**
 *
 */
export interface UploadImageParams {
  ownerId: string;
  buffer: Buffer;
}
