/**
 * Platform example — GET list, return ResponseDto напрямую.
 */
@Get()
@HttpCode(HttpStatus.OK)
async getList(
  @Query() query: GetItemListRequestDto,
  @Authority() authority: AuthorityModel,
): Promise<GetItemListResponseDto> {
  const list = await this.itemService.routeGetItemList(query, authority);

  return new GetItemListResponseDto(list);
}

// ❌ return { data: dto.data, total: dto.total, ... };
