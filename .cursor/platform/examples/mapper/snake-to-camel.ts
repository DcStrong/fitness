/**
 * Platform example — mapper: API snake_case → service camelCase.
 */
export function mapCreateItemRequestDtoToParams(
  dto: CreateItemRequestDto,
): RouteCreateItemParams {
  return {
    name: dto.name,
    ownerKey: dto.owner_key,
    payload: {
      type: dto.payload.type,
      timeStart: dto.payload.time_start,
      timeEnd: dto.payload.time_end,
    },
    tags: dto.tags?.map(t => ({
      type: t.address.type,
      value: t.address.value,
    })),
  };
}
