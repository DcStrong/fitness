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

/**
 *
 */
export interface UploadPortfolioImagesParams {
  ownerId: string;
  buffers: Buffer[];
}
