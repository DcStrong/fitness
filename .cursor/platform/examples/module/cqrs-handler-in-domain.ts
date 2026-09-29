/**
 * Platform example — CQRS handler в доменном модуле, не в infra.
 */
// ItemModule providers:
//   SaveItemToSearchCommandHandler  ← здесь
// ItemModule imports:
//   QueueProviderModule             ← только publish

@CommandHandler(SaveItemToSearchCommand)
export class SaveItemToSearchCommandHandler implements ICommandHandler<SaveItemToSearchCommand> {
  constructor(
    private readonly itemRepository: ItemRepository,
    private readonly queueProvider: QueueProvider,
  ) {}

  async execute(command: SaveItemToSearchCommand): Promise<void> {
    const item = await this.itemRepository.findOneById({ id: command.itemId });
    if (!item) return;

    await this.queueProvider.saveToDataSearch('items', new GetItemResponseDto(item));
  }
}
