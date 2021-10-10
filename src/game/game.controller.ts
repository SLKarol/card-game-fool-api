import {
  Body,
  Controller,
  Get,
  Post,
  UseGuards,
  UsePipes,
  Query,
  HttpException,
  HttpStatus,
} from '@nestjs/common';

import { GameShortInfo } from './types/gameInfo';
import { GameSettingsInfo } from './types/gameSettings';

import {
  CreateGameDto,
  GameOver,
  InfoNewGame,
  OpenGameDto,
} from './dto/game.dto';
import { User } from '@app/user/decorators/user.decorator';
import { UserEntity } from '@app/user/user.entity';
import { GameService } from './game.service';
import { JwtAuthGuard } from '@app/user/guards/jwt.guard';
import { BackendValidationPipe } from '@app/shared/pipes/backendValidation.pipe';
import {
  INVALID_REQUEST_PARAMETERS,
  USER_NOT_FOUND,
} from '@app/constants/messages';
import { UserService } from '@app/user/user.service';
import { TurnGameDto } from './dto/turn.dto';
import { ChatGateway } from '@app/gateway/chat.gateway';

@Controller('game')
export class GameController {
  constructor(
    private readonly gameService: GameService,
    private userService: UserService,
    private readonly socketGateway: ChatGateway,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @UsePipes(new BackendValidationPipe())
  async create(
    @User() currentUser: UserEntity,
    @Body('game') game: CreateGameDto,
  ): Promise<InfoNewGame> {
    // Проверка на то, что отправлены корректные данные
    if (!game) {
      throw new HttpException(
        { errors: { game: INVALID_REQUEST_PARAMETERS } },
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }

    const { opponent } = game;
    if (!opponent) {
      throw new HttpException(
        { errors: { opponent: INVALID_REQUEST_PARAMETERS } },
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    // Поиск оппонента
    const userOpponent = await this.userService.findUserByName(opponent);
    if (!userOpponent) {
      throw new HttpException(
        { errors: { opponent: USER_NOT_FOUND } },
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }

    const gameId = await this.gameService.createGame(
      currentUser,
      userOpponent.id_user,
    );
    return this.gameService.buildResponseGameId(gameId);
  }

  @Get('info')
  @UseGuards(JwtAuthGuard)
  async gameInfo(
    @User('id_user') currentUserId: string,
    @Query('id') idGame: string,
  ): Promise<{ game: GameShortInfo }> {
    const game = await this.gameService.getGameShortInfo(currentUserId, idGame);
    return { game };
  }

  @Get('setting')
  @UseGuards(JwtAuthGuard)
  async getSetting(
    @User('id_user') currentUserId: string,
    @Query('id') idGame: string,
  ): Promise<GameSettingsInfo> {
    try {
      const gameSettings = await this.gameService.getGameSetting(
        currentUserId,
        idGame,
      );
      return gameSettings;
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  @Get('open')
  @UseGuards(JwtAuthGuard)
  async getOpenGames(
    @User('id_user') currentUserId: string,
  ): Promise<{ games: OpenGameDto[] }> {
    // Выдать список открытых игр, где юзер участвует
    const games = await this.gameService.getOpenGames(currentUserId);
    return { games };
  }

  @Post('turn')
  @UseGuards(JwtAuthGuard)
  @UsePipes(new BackendValidationPipe())
  async turn(
    @User('id_user') currentUserId: string,
    @Body('turn') { cardId, gameId }: TurnGameDto,
  ): Promise<boolean> {
    await this.gameService.playerTurn({ cardId, gameId, currentUserId });
    return true;
  }

  @Post('finishTurn')
  @UseGuards(JwtAuthGuard)
  async finishTurn(
    @User('id_user') currentUserId: string,
    @Body('turn') { gameId }: Partial<TurnGameDto>,
  ): Promise<GameOver> {
    const whoAttack = await this.gameService.whoAttack(gameId);
    // Если атакует этот игрок, то он завершает ход
    if (whoAttack === currentUserId) {
      await this.gameService.finishTurn({
        gameId,
        currentUserId,
      });
    }
    await this.gameService.failDefence({ currentUserId, gameId });
    // Получить состояние игры: Игра ещё идёт?
    const gameReady = await this.gameService.checkGameOver(gameId);
    // Оповестить чат о состоянии игры
    this.socketGateway.server.in(gameId).emit('game', { gameReady });
    return { game: { id: gameId, gameReady } };
  }
}
