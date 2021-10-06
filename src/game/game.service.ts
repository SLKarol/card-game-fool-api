import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Not, Repository } from 'typeorm';

import { InfoNewGame, OpenGameDto } from './dto/game.dto';
import { GameShortInfo } from './types/gameInfo';
import { GameSettingsInfo } from './types/gameSettings';

import { GameEntity } from './entities/game.entity';
import { GameView } from './entities/gameView.entity';
import { CardsInHandsView } from './entities/cardsInHandsView.entity';
import { UserEntity } from '@app/user/user.entity';
import { ChatGateway } from '@app/gateway/chat.gateway';
import { TableService } from '@app/table/table.service';

@Injectable()
export class GameService {
  constructor(
    @InjectRepository(GameEntity)
    private readonly gameRepository: Repository<GameEntity>,
    @InjectRepository(GameView)
    private readonly gameViewRepository: Repository<GameView>,
    @InjectRepository(CardsInHandsView)
    private readonly сardsInHandsView: Repository<CardsInHandsView>,
    private readonly socketGateway: ChatGateway,
    private readonly tableService: TableService,
  ) {}

  async createGame(
    currentUser: UserEntity,
    opponentId: string,
  ): Promise<string> {
    try {
      const newGames = await this.gameRepository.query(
        'Select start_game($1, $2) as game;',
        [currentUser.id_user, opponentId],
      );
      return newGames[0]['game'] as string;
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  buildResponseGameId(id: string): InfoNewGame {
    return { game: { id } };
  }

  /**
   * Выдаёт краткую информацию о ире для пользователя
   */
  async getGameShortInfo(
    currentUserId: string,
    gameId: string,
  ): Promise<GameShortInfo> {
    try {
      const game = await this.gameViewRepository.findOne({
        where: { idGame: gameId, idUser: currentUserId },
        select: ['createdAt', 'whoseTurn'],
      });
      if (!game) {
        return { available: false, createdAt: '', id: '' };
      }
      return {
        available: game.whoseTurn !== null,
        id: gameId,
        createdAt: game.createdAt,
      };
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  /**
   * Пользователь запрашивает инфу о игре
   */
  async getGameSetting(
    currentUserId: string,
    gameId: string,
  ): Promise<GameSettingsInfo> {
    // Общая информация
    const game = await this.gameViewRepository.findOne({
      where: { idGame: gameId, idUser: currentUserId },
      select: [
        'attack',
        'numberPlayer',
        'trumpCard',
        'whoseTurn',
        'trumpCardValue',
        'trumpIdSuit',
        'trumpNameSuit',
        'countCards',
      ],
    });
    // Получить карты пользователя
    const userCards = await this.сardsInHandsView.find({
      where: { idGame: gameId, idUser: currentUserId },
      select: ['cardValue', 'idCard', 'idSuit', 'nameSuit'],
      order: { idCard: 'ASC' },
    });
    // Инфа об оппоненте
    const { opponentCards } = await this.сardsInHandsView
      .createQueryBuilder('cards')
      .select('COUNT(*)', 'opponentCards')
      .where('id_game = :id', { id: gameId })
      .andWhere('id_user <> :user', { user: currentUserId })
      .getRawOne();
    const { nameUser, numberPlayer } = await this.gameViewRepository.findOne({
      where: { idGame: gameId, idUser: Not(currentUserId) },
      select: ['nameUser', 'numberPlayer'],
    });

    return {
      game,
      userCards,
      opponent: {
        countCards: opponentCards,
        name: nameUser,
        numberPlayer,
      },
    };
  }

  /**
   * Выдать список открытых игр, где юзер участвует
   *  todo Процедура в разработке, пока выдаёт все игры
   */
  async getOpenGames(currentUserId: string): Promise<OpenGameDto[]> {
    const records = await this.gameViewRepository.query(
      `SELECT
      id_game as "idGame",
      name_user as "nameUser",
      created_at as "createdAt"
    FROM
      game_view
    WHERE
      id_game IN(
        SELECT
          id_game
        FROM
          game_view
        WHERE
          id_user = $1
      )
      AND id_user <> $1
    ORDER BY
      created_at`,
      [currentUserId],
    );
    return records as OpenGameDto[];
  }

  async playerTurn({
    gameId,
    cardId,
    currentUserId,
  }: {
    gameId: string;
    cardId: number;
    currentUserId: string;
  }): Promise<void> {
    // Игрок делает ход
    try {
      await this.gameViewRepository.query('SELECT move_player($1,$2,$3);', [
        gameId,
        currentUserId,
        cardId,
      ]);
      // Получить содержимое доски
      const tableInfo = await this.tableService.getTableContent(gameId);
      // Отправить через сокеты это состояние доски
      this.socketGateway.server.in(gameId).emit('table', tableInfo);
    } catch (e) {
      const { message } = e;

      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  /**
   * Завершить ход
   */
  async finishTurn({
    gameId,
    currentUserId,
  }: {
    gameId: string;
    currentUserId: string;
  }): Promise<boolean> {
    try {
      const gameOverTable = await this.gameRepository.query(
        'SELECT finish_turn($1, $2) as go;',
        [gameId, currentUserId],
      );
      const nextStep = gameOverTable[0]['go'] as boolean;
      if (nextStep) {
        // Отправить состояние игры сокетом
        this.socketGateway.server.in(gameId).emit('game', { nextStep });
      }
      return nextStep;
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  /**
   * Возвращает ID пользователя, который сейчас ходит
   */
  async whoAttack(gameId: string): Promise<string> {
    const re = await this.gameViewRepository.query(
      'SELECT id_user FROM game_view WHERE id_game=$1 AND whose_turn=number_player;',
      [gameId],
    );
    return re[0]['id_user'] as string;
  }

  /**
   * Тот, кто отбивается взял карты
   */
  async takeCards({
    gameId,
    currentUserId,
  }: {
    gameId: string;
    currentUserId: string;
  }): Promise<boolean> {
    try {
      // Общая информация
      const game = await this.gameViewRepository.findOne({
        where: { idGame: gameId, idUser: currentUserId },
        select: ['nameUser'],
      });
      // Оповестить, что игрок берёт карты
      this.socketGateway.server.in(gameId).emit('chat', {
        message: `${game.nameUser} берёт карты.`,
        sender: 'system',
        dateTime: new Date().toISOString(),
      });
      // Запуск процедуры взятия карт
      await this.gameRepository.query('SELECT fail_defence($1, $2);', [
        gameId,
        currentUserId,
      ]);
      // todo проверка: Игра окончилась? - Сейчас пока гвоздями прибито
      // Оповестить об окончании хода
      this.socketGateway.server.in(gameId).emit('game', { nextStep: true });
      return true;
    } catch (e) {
      const { message } = e;

      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }
}
