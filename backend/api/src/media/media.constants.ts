/** Максимальный размер одной картинки (аватар и фото портфолио). */
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/** Максимальный суммарный размер картинок в одной пакетной загрузке. */
export const MAX_IMAGES_TOTAL_BYTES = 25 * 1024 * 1024;

/** Максимум фото в портфолио тренера (минимума нет); он же предел пакетной загрузки. */
export const MAX_PORTFOLIO_PHOTOS = 5;

/** Запас над лимитом multer, чтобы слишком большой файл доходил до сервиса и получал код IMAGE_TOO_LARGE. */
export const MULTER_SLACK_BYTES = 1024;

/** Длинная сторона фото портфолио после обработки, px. */
export const PORTFOLIO_IMAGE_MAX_SIDE = 1600;

/** Длинная сторона аватара после обработки, px. */
export const AVATAR_IMAGE_MAX_SIDE = 512;

/** Качество WebP (0–100). */
export const WEBP_QUALITY = 80;
