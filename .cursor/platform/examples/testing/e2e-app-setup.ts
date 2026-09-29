/**
 * Platform example — e2e: test app с override внешних зависимостей.
 */
export async function createTestApp(): Promise<INestApplication> {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
    .overrideModule(QueueProviderModule)
    .useModule(E2eQueueProviderModule)
    .overrideProvider(PermissionService)
    .useClass(TestPermissionService)
    .overrideProvider(ExternalApiClient)
    .useValue(stubExternalApi)
    .compile();

  const app = moduleRef.createNestApplication();
  await app.init();

  return app;
}

// afterEach: truncateTables(dataSource)
// auth: authHeader(TEST_LOGINS.ADMIN)
// assert: assertResponseMatchesContract(res, contract.scenario)
