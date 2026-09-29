import 'reflect-metadata';
import { validate } from 'class-validator';
import { BookingRequestListQueryDto } from './booking-request-list-query.dto';
import { RejectBookingRequestDto } from './reject-booking-request.dto';

describe('Валидация DTO заявки', () => {
  it('требует допустимую причину отклонения', async () => {
    const missing = new RejectBookingRequestDto();
    const unsupported = Object.assign(new RejectBookingRequestDto(), {
      reason: 'unknown',
    });

    await expect(validate(missing)).resolves.not.toHaveLength(0);
    await expect(validate(unsupported)).resolves.not.toHaveLength(0);
  });

  it('ограничивает размер страницы', async () => {
    const query = Object.assign(new BookingRequestListQueryDto(), {
      page: 1,
      limit: 51,
    });

    await expect(validate(query)).resolves.not.toHaveLength(0);
  });
});
