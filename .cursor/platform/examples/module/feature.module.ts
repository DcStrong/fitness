/**
 * Platform example — feature module wiring.
 */
@Module({
  imports: [
    CqrsModule,
    TypeOrmModule.forFeature([ItemEntity, ItemMetaEntity]),
  ],
  providers: [
    ItemRepository,
    ItemService,
    ItemSideEffectCommandHandler,
  ],
  exports: [ItemService, ItemRepository],
})
export class ItemModule {}
