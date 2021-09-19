import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { GameEntity } from './entities/game.entity';
import { GameView } from './entities/gameView.entity';
import { CardsInHandsView } from './entities/cardsInHandsView.entity';
import { GameCardsEntity } from './entities/gameCards.entity';
import { GameController } from './game.controller';
import { GameService } from './game.service';
import { UserModule } from '@app/user/user.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([GameEntity]),
    TypeOrmModule.forFeature([GameView]),
    TypeOrmModule.forFeature([CardsInHandsView]),
    TypeOrmModule.forFeature([GameCardsEntity]),
    UserModule,
  ],
  controllers: [GameController],
  providers: [GameService],
})
export class GameModule {}
