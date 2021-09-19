import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CardsInTableView } from './entities/cardsInTableView.entity';

@Injectable()
export class TableService {
  constructor(
    @InjectRepository(CardsInTableView)
    private readonly cardsInTableViewRepository: Repository<CardsInTableView>,
  ) {}

  async getTableContent(currentUserId: string, idGame: string): Promise<any> {
    try {
      const table = await this.cardsInTableViewRepository.find({
        where: { idGame },
        select: ['idGameTable', 'idCard', 'numbCard', 'numberTurn'],
      });
      return table;
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }
}
