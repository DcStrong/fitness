import sharp from 'sharp';
import { processImageToWebp } from './image-processor.helper';

describe('processImageToWebp', () => {
  /**
   *
   */
  async function make(width: number, height: number): Promise<Buffer> {
    return sharp({ create: { width, height, channels: 3, background: '#336699' } })
      .jpeg()
      .withMetadata({ exif: { IFD0: { Copyright: 'secret' } } })
      .toBuffer();
  }

  it('конвертирует в webp и вписывает в maxSide без увеличения', async () => {
    const big = await processImageToWebp(await make(3000, 2000), 1600);
    const bigMeta = await sharp(big).metadata();
    expect(bigMeta).toMatchObject({ format: 'webp', width: 1600, height: 1067 });

    const small = await sharp(await processImageToWebp(await make(300, 200), 1600)).metadata();
    expect(small).toMatchObject({ width: 300, height: 200 });
  });

  it('не сохраняет EXIF', async () => {
    const meta = await sharp(await processImageToWebp(await make(100, 100), 512)).metadata();

    expect(meta.exif).toBeUndefined();
  });

  it('отвечает IMAGE_CORRUPT на битый файл', async () => {
    const broken = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(10)]);

    await expect(processImageToWebp(broken, 512)).rejects.toMatchObject({
      response: { code: 'IMAGE_CORRUPT' },
    });
  });
});
