/**
 * Platform example — response DTO: constructor от service returns.
 */
export class GetItemResponseDto implements Api.GetItem.ResponseBody {
  id!: number;
  created_at!: number;
  updated_at!: number;
  name!: string;
  status!: ItemStatus;

  constructor(data: RouteGetItemReturns) {
    this.id = data.id;
    this.name = data.name ?? '';
    this.status = data.status;
    this.created_at = toUnix(data.createdAt);
    this.updated_at = toUnix(data.updatedAt);
    // вложенные блоки — mapMeta(data), mapPayload(data)
  }
}
