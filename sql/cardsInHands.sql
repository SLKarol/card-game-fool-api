CREATE
OR REPLACE VIEW cards_in_hands AS
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

COMMENT ON VIEW cards_in_hands IS 'Карты у игрока';