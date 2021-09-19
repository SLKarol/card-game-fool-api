import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import { getOrmConfig } from './configs/ormconfig';
import { GameModule } from './game/game.module';
import { ChatModule } from './gateway/chat.module';
import { TableModule } from './table/table.module';
import { UserModule } from './user/user.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: getOrmConfig,
    }),
    UserModule,
    GameModule,
    ChatModule,
    TableModule,
  ],
})
export class AppModule {}
