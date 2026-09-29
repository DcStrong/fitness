/**
 * Platform example — unit test сервиса: моки границ, наблюдаемый результат.
 */
describe('ItemService', () => {
  let service: ItemService;
  let repository: jest.Mocked<ItemRepository>;
  let permissionService: jest.Mocked<PermissionService>;

  beforeEach(() => {
    repository = { findOneById: jest.fn(), createItem: jest.fn() } as never;
    permissionService = { readAccessContext: jest.fn() } as never;
    service = new ItemService(repository, permissionService, /* ... */);
    jest.clearAllMocks();
  });

  it('должен выбросить NoAccessHttpException без прав', async () => {
    permissionService.readAccessContext.mockResolvedValue(noAccessContext);
    repository.findOneById.mockResolvedValue(sampleItem());

    await expect(service.routeGetItem({ id: 1 }, authority))
      .rejects.toBeInstanceOf(NoAccessHttpException);
  });
});
