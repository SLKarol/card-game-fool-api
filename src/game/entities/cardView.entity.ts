import { ViewEntity, ViewColumn } from 'typeorm';

@ViewEntity({
  expression: `
  SELECT game.id_game,
  SELECT
  playing_card.id_card,
  playing_card.id_suit,
  playing_card.card_value,
  suit.name_suit
FROM
  playing_card
  JOIN suit ON suit.id_suit = playing_card.id_suit  
  `,
  name: 'playing_card_view',
  synchronize: false,
})
export class CardView {
  @ViewColumn({ name: 'id_card' })
  idGame: number;

  @ViewColumn({ name: 'id_suit' })
  idSuit: number;

  @ViewColumn({ name: 'card_value' })
  cardValue: number;

  @ViewColumn({ name: 'name_suit' })
  nameSuit: string;
}
