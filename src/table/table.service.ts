import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { TableInfo } from './types/tableInfo';
import { CardsInTableView } from './entities/cardsInTableView.entity';

@Injectable()
export class TableService {
  constructor(
    @InjectRepository(CardsInTableView)
    private readonly cardsInTableViewRepository: Repository<CardsInTableView>,
  ) {}

  /**
   * Выдать информацию по игровому столу
   */
  async getTableContent(idGame: string): Promise<TableInfo> {
    try {
      const table = await this.cardsInTableViewRepository.query(
        `with t (numb_card, attack, id_card) as (
select 
numb_card, 
case when attack=1 then 'attack' else 'defence' end as attack,
id_card 
from cards_in_table where id_game =$1 order by numb_card 
)
select json_object_agg(numb_card, joa) as table
from (
    select numb_card, json_object_agg(attack, id_card) as joa
    from t
    group by numb_card
) s
        `,
        [idGame],
      );
      return table[0]['table'];
    } catch (e) {
      const { message } = e;
      throw new HttpException(message || e, HttpStatus.UNPROCESSABLE_ENTITY);
    }
  }
}
