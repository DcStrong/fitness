/**
 * Platform example — dynamic module с ports (слабая связность).
 */
export interface HistoryModuleAsyncOptions extends Pick<ModuleMetadata, 'imports'> {
  inject?: (string | symbol | (new (...args: never[]) => unknown))[];
  useFactory: (...args: unknown[]) => {
    access: HistoryAccessPort;
    index: HistoryIndexPort;
  };
}

@Module({})
export class HistoryModule {
  static registerAsync(options: HistoryModuleAsyncOptions): DynamicModule {
    return {
      global: true,
      module: HistoryModule,
      imports: [TypeOrmModule.forFeature([HistoryEntity]), ...options.imports ?? []],
      providers: [
        {
          provide: HISTORY_ACCESS_PORT,
          useFactory: (...args: unknown[]) => options.useFactory(...args).access,
          inject: options.inject ?? [],
        },
        HistoryService,
      ],
      exports: [HistoryService],
    };
  }
}
