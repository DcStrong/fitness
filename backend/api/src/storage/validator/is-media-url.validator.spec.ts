import { isMediaUrl } from './is-media-url.validator';

describe('isMediaUrl', () => {
  const original = process.env['S3_PUBLIC_URL'];

  afterEach(() => {
    if (original === undefined) {
      delete process.env['S3_PUBLIC_URL'];
    } else {
      process.env['S3_PUBLIC_URL'] = original;
    }
  });

  it('принимает любую https-ссылку', () => {
    expect(isMediaUrl('https://example.com/a.jpg')).toBe(true);
  });

  it('отклоняет внешний http и не-URL', () => {
    expect(isMediaUrl('http://example.com/a.jpg')).toBe(false);
    expect(isMediaUrl('javascript:alert(1)')).toBe(false);
    expect(isMediaUrl(42)).toBe(false);
  });

  it('принимает http-адрес нашего хранилища', () => {
    process.env['S3_PUBLIC_URL'] = 'http://localhost:9000/media/';

    expect(isMediaUrl('http://localhost:9000/media/images/u/x.png')).toBe(true);
    expect(isMediaUrl('http://localhost:9000/other/x.png')).toBe(false);
  });
});
