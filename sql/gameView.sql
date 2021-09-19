CREATE
OR REPLACE VIEW game_view AS
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
  (
    SELECT
      COUNT(*)
    FROM
      game_card
    WHERE
      id_game = game.id_game
  ) AS countCards
FROM
  game
  JOIN player ON game.id_game = player.id_game
  JOIN users ON player.id_user = users.id_user
  JOIN playing_card_view ON playing_card_view.id_card = game.trump_card;