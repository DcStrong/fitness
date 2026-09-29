/**
 * Platform example — service route с policy и transactional write.
 */
@Transactional()
async routeCreateItem(
  params: RouteCreateItemParams,
  authority: AuthorityModel,
): Promise<RouteCreateItemReturns> {
  const policy = await this.getPolicy(authority);
  assertHaveAccess(policy.canManage());

  const entity = await this.itemRepository.createItem({
    name: params.name,
    status: ItemStatus.Draft,
  });

  this.commandBus.execute(new IndexItemCommand(entity.id));

  return entity;
}
