/**
 * Platform example — guard на уровне класса (все методы защищены).
 */
@Controller('items')
@UseGuards(JwtAuthGuard)
export class ItemController {
  @Get(':id')
  async getOne(
    @Param('id') id: number,
    @Authority() authority: AuthorityModel,
  ): Promise<GetItemResponseDto> {
    const item = await this.itemService.routeGetItem({ id }, authority);

    return new GetItemResponseDto(item);
  }
}
