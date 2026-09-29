/**
 * Platform example — POST command handler.
 * Иллюстрация паттерна; не импортировать в runtime.
 */
@Controller('items')
@UseGuards(JwtAuthGuard)
export class ItemController {
  constructor(private readonly itemService: ItemService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Req() request: Request,
    @Body() dto: CreateItemRequestDto,
    @Authority() authority: AuthorityModel,
  ): Promise<CreateItemResponseDto> {
    const params = mapCreateItemRequestDtoToParams(dto);
    const created = await this.itemService.routeCreateItem(params, authority);

    request.res?.setHeader('Location', `/items/${created.id}`);

    return new CreateItemResponseDto(created);
  }
}
