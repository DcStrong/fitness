/**
 * Platform example — repository: preload → save → reload (без mutate entity).
 */
async updateItemAfterPublish(params: UpdateItemAfterPublishParams): Promise<ItemModel> {
  const denorm = mapTagsToDenorm(params.tags);

  const entity = await this.itemRepository.preload({
    id: params.id,
    text: params.text,
    status: params.status,
    tagIds: denorm.tagIds,
    meta: {
      id: params.metaId,
      publishedAt: params.meta.publishedAt,
      externalId: params.meta.externalId,
    },
  });

  if (!entity) {
    throw new Error(`Item ${params.id} not found for publish update`);
  }

  await this.itemRepository.save(entity);

  const reloaded = await this.findOneById({ id: params.id });
  if (!reloaded) {
    throw new Error(`Item ${params.id} not found after publish save`);
  }

  return reloaded;
}
