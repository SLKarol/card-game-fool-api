CREATE
OR REPLACE VIEW cards_in_table AS
SELECT
  game_table.id_game_table,
  game.id_game,
  game.number_turn,
  player.id_user,
  player.id_player,
  player.number_player,
  game_table.numb_card,
  playing_card.id_card,
  playing_card.id_suit,
  playing_card.card_value
FROM
  game
  JOIN player ON game.id_game = player.id_game
  JOIN game_table ON game_table.id_player = player.id_player
  JOIN playing_card ON game_table.id_card = playing_card.id_card;

COMMENT ON VIEW cards_in_table IS 'Все карты на столе';