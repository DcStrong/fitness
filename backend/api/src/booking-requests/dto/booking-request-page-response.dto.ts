import type { BookingRequestPage } from '../interface';
import { BookingRequestResponseDto } from './booking-request-response.dto';

export class BookingRequestPageResponseDto {
  items: BookingRequestResponseDto[];

  meta: BookingRequestPage['meta'];

  constructor(page: BookingRequestPage) {
    this.items = page.items.map(item => new BookingRequestResponseDto(item));
    this.meta = page.meta;
  }
}
