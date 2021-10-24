import { ViewEntity, ViewColumn } from 'typeorm';

@ViewEntity({
  expression: `
SELECT game_table.id_game_table,
  game.id_game,
  game.number_turn,
  player.id_user,
  player.id_player,
  player.number_player,
  game_table.numb_card,
  playing_card.id_card,
  playing_card.id_suit,
  playing_card.card_value,
  CASE
  WHEN game.whose_turn = player.number_player THEN 1
  ELSE 0
END AS attack  
FROM game
   JOIN player ON game.id_game = player.id_game
   JOIN game_table ON game_table.id_player = player.id_player
   JOIN playing_card ON game_table.id_card = playing_card.id_card 
  `,
  name: 'cards_in_table',
  synchronize: false,
})
export class CardsInTableView {
  @ViewColumn({ name: 'id_game_table' })
  idGameTable: string;

  @ViewColumn({ name: 'id_game' })
  idGame: string;

  @ViewColumn({ name: 'number_turn' })
  numberTurn: number;

  @ViewColumn({ name: 'id_user' })
  idUser: string;

  @ViewColumn({ name: 'id_player' })
  idPlayer: string;

  @ViewColumn({ name: 'number_player' })
  numberPlayer: number;

  @ViewColumn({ name: 'numb_card' })
  numbCard: number;

  @ViewColumn({ name: 'id_card' })
  idCard: number;

  @ViewColumn({ name: 'id_suit' })
  idSuit: number;

  @ViewColumn({ name: 'card_value' })
  cardValue: number;

  @ViewColumn({ name: 'attack' })
  attack: number;
}
