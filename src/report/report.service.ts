import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ScoreEntity } from './entities/score.entity';
import type { MyGames } from './types/myGames';

@Injectable()
export class ReportService {
  constructor(
    @InjectRepository(ScoreEntity)
    private readonly scoreEntity: Repository<ScoreEntity>,
  ) {}

  /**
   * Выдать информацию по игровому столу
   */
  async getGameScore(idGame: string): Promise<string[]> {
    try {
      const gameScore = await this.scoreEntity.find({
        where: { game: idGame },
        relations: ['user'],
      });
      return gameScore.map((r) => r.user.name_user);
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }

  async getMyGames(currentUserId: string): Promise<MyGames> {
    const sqlResult = await Promise.all([
      this.scoreEntity.query(
        'select count(*) as c from player where id_user = $1',
        [currentUserId],
      ),
      this.scoreEntity.query(
        'select count(*) as c from score  where id_user = $1',
        [currentUserId],
      ),
    ]);
    const allMyGames = parseInt(sqlResult[0][0].c);
    const myVictory = parseInt(sqlResult[1][0].c);
    return {
      allMyGames,
      myVictory,
    };
  }
}
