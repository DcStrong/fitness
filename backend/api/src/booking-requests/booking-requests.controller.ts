import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { BookingRequestsService } from './booking-requests.service';
import { AlternateBookingRequestDto } from './dto/alternate-booking-request.dto';
import { BookingRequestListQueryDto } from './dto/booking-request-list-query.dto';
import { BookingRequestPageResponseDto } from './dto/booking-request-page-response.dto';
import { BookingRequestResponseDto } from './dto/booking-request-response.dto';
import { CreateBookingRequestDto } from './dto/create-booking-request.dto';
import { RejectBookingRequestDto } from './dto/reject-booking-request.dto';
import type { PendingCountReturns } from './interface';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('booking-requests')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class BookingRequestsController {
  constructor(private readonly bookingRequests: BookingRequestsService) {}

  /**
   *
   */
  @Post()
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_CREATE)
  async create(
    @Req() req: RequestWithUser,
    @Body() dto: CreateBookingRequestDto,
  ): Promise<BookingRequestResponseDto> {
    return new BookingRequestResponseDto(
      await this.bookingRequests.create({
        studentId: req.user.id,
        scheduleSlotId: dto.scheduleSlotId,
      }),
    );
  }

  /**
   *
   */
  @Get('mine')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_READ_OWN)
  async mine(
    @Req() req: RequestWithUser,
    @Query() query: BookingRequestListQueryDto,
  ): Promise<BookingRequestPageResponseDto> {
    return new BookingRequestPageResponseDto(
      await this.bookingRequests.listMine(req.user.id, query),
    );
  }

  /**
   *
   */
  @Post(':id/withdraw')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_READ_OWN)
  async withdraw(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingRequestResponseDto> {
    return new BookingRequestResponseDto(
      await this.bookingRequests.withdraw(id, req.user.id),
    );
  }

  /**
   *
   */
  @Get('inbox')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_READ_INBOX)
  async inbox(
    @Req() req: RequestWithUser,
    @Query() query: BookingRequestListQueryDto,
  ): Promise<BookingRequestPageResponseDto> {
    return new BookingRequestPageResponseDto(
      await this.bookingRequests.inbox(req.user.id, query),
    );
  }

  /**
   *
   */
  @Get('pending-count')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_READ_INBOX)
  async pendingCount(
    @Req() req: RequestWithUser,
  ): Promise<PendingCountReturns> {
    return this.bookingRequests.pendingCount(req.user.id);
  }

  /**
   *
   */
  @Post(':id/accept')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_RESPOND)
  async accept(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingRequestResponseDto> {
    return new BookingRequestResponseDto(
      await this.bookingRequests.accept(id, req.user.id),
    );
  }

  /**
   *
   */
  @Post(':id/reject')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_RESPOND)
  async reject(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectBookingRequestDto,
  ): Promise<BookingRequestResponseDto> {
    return new BookingRequestResponseDto(
      await this.bookingRequests.reject({
        requestId: id,
        coachId: req.user.id,
        reason: dto.reason,
        ...dto.comment !== undefined ? { comment: dto.comment } : {},
      }),
    );
  }

  /**
   *
   */
  @Post(':id/alternate')
  @RequirePermissions(PERMISSIONS.BOOKING_REQUESTS_RESPOND)
  async alternate(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AlternateBookingRequestDto,
  ): Promise<BookingRequestResponseDto> {
    return new BookingRequestResponseDto(
      await this.bookingRequests.alternate({
        requestId: id,
        coachId: req.user.id,
        startsAt: dto.startsAt,
      }),
    );
  }
}
