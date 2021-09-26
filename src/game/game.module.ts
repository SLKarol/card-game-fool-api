import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { GameEntity } from './entities/game.entity';
import { GameView } from './entities/gameView.entity';
import { CardsInHandsView } from './entities/cardsInHandsView.entity';
import { GameController } from './game.controller';
import { GameService } from './game.service';
import { UserModule } from '@app/user/user.module';
import { ChatModule } from '@app/gateway/chat.module';
import { TableModule } from '@app/table/table.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([GameEntity]),
    TypeOrmModule.forFeature([GameView]),
    TypeOrmModule.forFeature([CardsInHandsView]),
    UserModule,
    ChatModule,
    TableModule,
  ],
  controllers: [GameController],
  providers: [GameService],
})
export class GameModule {}
