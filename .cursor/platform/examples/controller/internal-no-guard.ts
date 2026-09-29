/**
 * Platform example — internal/service API без JwtAuthGuard.
 */
@Controller('internal/items')
export class ItemInternalController {
  @Get()
  async getList(@Query() query: GetItemListRequestDto): Promise<GetItemListResponseDto> {
    const list = await this.itemInternalService.routeInternalGetItemList(query);

    return new GetItemListResponseDto(list);
  }

  @Get(':id')
  async getOne(@Param('id') id: number): Promise<GetItemResponseDto> {
    const item = await this.itemInternalService.routeInternalGetItem({ id });

    return new GetItemResponseDto(item);
  }
}
