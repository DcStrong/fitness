import 'reflect-metadata';
import { config } from 'dotenv';
import { join } from 'path';
import { DataSource } from 'typeorm';
import { resolveDatabaseUrl } from './database-url';
import { entities } from './entity';

config({ path: join(__dirname, '..', '..', '.env') });
config({ path: join(__dirname, '..', '..', '..', '.env') });

export default new DataSource({
  type: 'postgres',
  url: resolveDatabaseUrl(),
  entities,
  migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
  synchronize: false,
  logging: false,
});
