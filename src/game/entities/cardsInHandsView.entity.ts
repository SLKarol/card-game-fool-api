import { ViewEntity, ViewColumn } from 'typeorm';

@ViewEntity({
  expression: `
SELECT
  player.id_game,
  player.id_user,
  player.id_player,
  player.number_player,
  player_card.id_card,
  playing_card.id_suit,
  playing_card.card_value,
  suit.name_suit
FROM
  player
  JOIN player_card ON player.id_player = player_card.id_player
  JOIN playing_card ON playing_card.id_card = player_card.id_card
  JOIN suit ON suit.id_suit = playing_card.id_suit; 
  `,
  name: 'cards_in_hands',
  // synchronize: false,
})
export class CardsInHandsView {
  @ViewColumn({ name: 'id_game' })
  idGame: string;

  @ViewColumn({ name: 'id_user' })
  idUser: string;

  @ViewColumn({ name: 'id_player' })
  idPlayer: string;

  @ViewColumn({ name: 'number_player' })
  numberPlayer: number;

  @ViewColumn({ name: 'id_card' })
  idCard: number;

  @ViewColumn({ name: 'id_suit' })
  idSuit: number;

  @ViewColumn({ name: 'card_value' })
  cardValue: number;

  @ViewColumn({ name: 'name_suit' })
  nameSuit: string;
}
