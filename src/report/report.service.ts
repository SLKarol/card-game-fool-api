import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ScoreEntity } from './entities/score.entity';

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
}
