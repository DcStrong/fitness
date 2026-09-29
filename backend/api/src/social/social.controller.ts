import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  PaginationQueryDto,
  ReorderPortfolioDto,
  SavePortfolioItemDto,
  SaveReviewDto,
  TrainerDiscoveryQueryDto,
  UpdatePrivacyDto,
  UpdateProfileDto,
} from './dto/social-request.dto';
import {
  OwnerProfileResponseDto,
  PortfolioItemResponseDto,
  PublicReviewResponseDto,
  PublicTrainerResponseDto,
  ReviewResponseDto,
  TrainerDiscoveryResponseDto,
} from './dto/social-response.dto';
import { LinkedContactsResponseDto } from './dto/linked-contacts-response.dto';
import type { SocialActor } from './interface';
import { SocialService } from './social.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('profiles')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ProfilesController {
  constructor(private readonly social: SocialService) {}

  /**
   *
   */
  @Get('me')
  @RequirePermissions(PERMISSIONS.PROFILES_UPDATE_OWN)
  async me(@Req() req: RequestWithUser) {
    return new OwnerProfileResponseDto(
      await this.social.getOwnProfile(this.actor(req)),
    );
  }

  /**
   *
   */
  @Put('me')
  @RequirePermissions(PERMISSIONS.PROFILES_UPDATE_OWN)
  async update(
    @Req() req: RequestWithUser,
    @Body() dto: UpdateProfileDto,
  ) {
    return new OwnerProfileResponseDto(
      await this.social.updateOwnProfile(this.actor(req), dto),
    );
  }

  /**
   *
   */
  @Put('me/privacy')
  @RequirePermissions(PERMISSIONS.PROFILES_MANAGE_PRIVACY)
  async privacy(
    @Req() req: RequestWithUser,
    @Body() dto: UpdatePrivacyDto,
  ) {
    return new OwnerProfileResponseDto(
      await this.social.updateOwnPrivacy(this.actor(req), dto),
    );
  }

  /**
   *
   */
  @Get(':id/contacts')
  @RequirePermissions(PERMISSIONS.PROFILES_READ_LINKED_CONTACTS)
  async linkedContacts(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<LinkedContactsResponseDto> {
    return new LinkedContactsResponseDto(
      await this.social.getLinkedContacts(this.actor(req), id),
    );
  }

  /**
   *
   */
  @Post('me/portfolio')
  @RequirePermissions(PERMISSIONS.PORTFOLIO_MANAGE_OWN)
  async createPortfolio(
    @Req() req: RequestWithUser,
    @Body() dto: SavePortfolioItemDto,
  ) {
    return new PortfolioItemResponseDto(
      await this.social.createPortfolioItem(this.actor(req), dto),
    );
  }

  /**
   *
   */
  @Put('me/portfolio/reorder')
  @RequirePermissions(PERMISSIONS.PORTFOLIO_MANAGE_OWN)
  async reorderPortfolio(
    @Req() req: RequestWithUser,
    @Body() dto: ReorderPortfolioDto,
  ) {
    return (
      await this.social.reorderPortfolio(this.actor(req), dto)
    ).map(item => new PortfolioItemResponseDto(item));
  }

  /**
   *
   */
  @Put('me/portfolio/:id')
  @RequirePermissions(PERMISSIONS.PORTFOLIO_MANAGE_OWN)
  async updatePortfolio(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SavePortfolioItemDto,
  ) {
    return new PortfolioItemResponseDto(
      await this.social.updatePortfolioItem(this.actor(req), id, dto),
    );
  }

  /**
   *
   */
  @Delete('me/portfolio/:id')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.PORTFOLIO_MANAGE_OWN)
  async deletePortfolio(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.social.deletePortfolioItem(this.actor(req), id);
  }

  /**
   *
   */
  @Get('me/reviews')
  @RequirePermissions(PERMISSIONS.REVIEWS_READ)
  async receivedReviews(
    @Req() req: RequestWithUser,
    @Query() query: PaginationQueryDto,
  ) {
    return this.social.listReceivedReviews(this.actor(req), query);
  }

  /**
   *
   */
  private actor(req: RequestWithUser): SocialActor {
    return {
      id: req.user.id,
      email: req.user.email,
      roles: req.user.roles ?? [],
    };
  }
}

@Controller('trainers')
@UseGuards(JwtAuthGuard, PermissionsGuard)
@RequirePermissions(PERMISSIONS.PROFILES_READ_PUBLIC)
export class TrainersController {
  constructor(private readonly social: SocialService) {}

  /**
   *
   */
  @Get()
  async list(@Query() query: TrainerDiscoveryQueryDto) {
    return new TrainerDiscoveryResponseDto(
      await this.social.listTrainers(query),
    );
  }

  /**
   *
   */
  @Get(':id/reviews')
  @RequirePermissions(
    PERMISSIONS.PROFILES_READ_PUBLIC,
    PERMISSIONS.REVIEWS_READ,
  )
  async reviews(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: PaginationQueryDto,
  ) {
    const page = await this.social.listTrainerReviews(id, query);

    return {
      items: page.items.map(item => new PublicReviewResponseDto(item)),
      meta: page.meta,
    };
  }

  /**
   *
   */
  @Get(':id')
  async get(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return new PublicTrainerResponseDto(
      await this.social.getTrainer(this.actor(req), id),
    );
  }

  /**
   *
   */
  private actor(req: RequestWithUser): SocialActor {
    return {
      id: req.user.id,
      email: req.user.email,
      roles: req.user.roles ?? [],
    };
  }
}

@Controller('sessions')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SessionReviewsController {
  constructor(private readonly social: SocialService) {}

  /**
   *
   */
  @Post(':id/review')
  @RequirePermissions(PERMISSIONS.REVIEWS_CREATE_OWN)
  async create(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveReviewDto,
  ) {
    return new ReviewResponseDto(
      await this.social.createReview(this.actor(req), id, dto),
    );
  }

  /**
   *
   */
  private actor(req: RequestWithUser): SocialActor {
    return {
      id: req.user.id,
      email: req.user.email,
      roles: req.user.roles ?? [],
    };
  }
}

@Controller('reviews')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ReviewsController {
  constructor(private readonly social: SocialService) {}

  /**
   *
   */
  @Get('eligible')
  @RequirePermissions(PERMISSIONS.REVIEWS_READ)
  async eligible(@Req() req: RequestWithUser) {
    return this.social.listEligible(this.actor(req));
  }

  /**
   *
   */
  @Get('mine')
  @RequirePermissions(PERMISSIONS.REVIEWS_READ)
  async mine(@Req() req: RequestWithUser) {
    return (await this.social.listMine(this.actor(req))).map(
      item => new ReviewResponseDto(item),
    );
  }

  /**
   *
   */
  @Put(':id')
  @RequirePermissions(PERMISSIONS.REVIEWS_UPDATE_OWN)
  async update(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveReviewDto,
  ) {
    return new ReviewResponseDto(
      await this.social.updateOwnReview(this.actor(req), id, dto),
    );
  }

  /**
   *
   */
  private actor(req: RequestWithUser): SocialActor {
    return {
      id: req.user.id,
      email: req.user.email,
      roles: req.user.roles ?? [],
    };
  }
}
