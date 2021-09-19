import { join } from 'path';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConnectionOptions } from 'typeorm';

export const getOrmConfig = async (
  configService: ConfigService,
): Promise<TypeOrmModuleOptions> => {
  const url = configService.get('DATABASE_URL');
  const isNotLocalhost = url.indexOf('@localhost') === -1;
  return {
    url,
    type: 'postgres',
    port: 5432,
    entities: [join(__dirname, '/../**/**.entity{.ts,.js}')],
    synchronize: false,
    migrations: [join(__dirname, '/../migrations/**/*{.ts,.js}')],
    cli: {
      migrationsDir: 'src/migrations',
    },
    ssl: isNotLocalhost ? true : undefined,
    extra: isNotLocalhost && {
      ssl: {
        rejectUnauthorized: false,
      },
    },
  };
};

const { DATABASE_URL = '' } = process.env;
const config: ConnectionOptions = {
  url: DATABASE_URL,
  type: 'postgres',
  entities: [join(__dirname, '/../**/**.entity{.ts,.js}')],
  synchronize: false,
  migrations: [join(__dirname, '/../migrations/**/*{.ts,.js}')],
  cli: {
    migrationsDir: 'src/migrations',
  },
  ssl: DATABASE_URL.indexOf('@localhost') === -1,
  extra: DATABASE_URL.indexOf('@localhost') === -1 && {
    ssl: {
      rejectUnauthorized: false,
    },
  },
};

export default config;
