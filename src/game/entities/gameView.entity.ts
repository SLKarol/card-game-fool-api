import { ViewEntity, ViewColumn } from 'typeorm';

@ViewEntity({
  expression: `
SELECT
  game.id_game,
  game.whose_turn,
  game.attack,
  game.trump_card,
  player.id_user,
  users.name_user,
  player.number_player,
  player.robot,
  player.id_player,
  game.created_at,
  playing_card_view.id_suit AS trump_id_suit,
  playing_card_view.card_value AS trump_card_value,
  playing_card_view.name_suit AS trump_name_suit,
  (SELECT count(*) FROM game_card	where id_game=game.id_game) as count_cards
FROM
  game
  JOIN player ON game.id_game = player.id_game
  JOIN users ON player.id_user = users.id_user
  JOIN playing_card_view ON playing_card_view.id_card = game.trump_card  
  `,
  name: 'game_view',
  synchronize: false,
})
export class GameView {
  @ViewColumn({ name: 'id_game' })
  idGame: string;

  @ViewColumn({ name: 'whose_turn' })
  whoseTurn: number;

  @ViewColumn()
  attack: boolean;

  @ViewColumn({ name: 'trump_card' })
  trumpCard: number;

  @ViewColumn({ name: 'id_user' })
  idUser: string;

  @ViewColumn({ name: 'name_user' })
  nameUser: string;

  @ViewColumn({ name: 'id_player' })
  idPlayer: string;

  @ViewColumn({ name: 'number_player' })
  numberPlayer: number;

  @ViewColumn()
  robot: boolean;

  @ViewColumn({ name: 'created_at' })
  createdAt: string;

  @ViewColumn({ name: 'trump_id_suit' })
  trumpIdSuit: number;
  @ViewColumn({ name: 'trump_card_value' })
  trumpCardValue: number;
  @ViewColumn({ name: 'trump_name_suit' })
  trumpNameSuit: number;

  @ViewColumn({ name: 'count_cards' })
  countCards: number;
}
