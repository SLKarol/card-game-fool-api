CREATE
OR REPLACE FUNCTION set_add_cards(game_id uuid) RETURNS BOOLEAN AS $$
DECLARE
  /* Игрок */
  player_in_game RECORD;

/* Сколько карт дать */
need_cnt_cards INT;

BEGIN
  FOR player_in_game IN
  SELECT
    whose_turn = number_player AS current_player,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
  ORDER BY
    current_player DESC,
    number_player
  LOOP
  SELECT
    6 - COUNT(*) INTO need_cnt_cards
  FROM
    player_card
  WHERE
    id_player = player_in_game.id_player;

IF (need_cnt_cards > 0) THEN
/* Сдать игроку need_cnt_cards из колоды */
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player_in_game.id_player,
  id_card
FROM
  game_card
WHERE
  id_game = game_id
ORDER BY
  id_game_card
LIMIT
  need_cnt_cards;

-- Удалить из колоды
DELETE FROM
  game_card
WHERE
  id_game_card IN (
    SELECT
      id_game_card
    FROM
      game_card
    WHERE
      id_game = game_id
    ORDER BY
      id_game_card
    LIMIT
      need_cnt_cards
  );

END IF;

END
LOOP
;

RETURN TRUE;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION finish_attack(uuid, uuid) IS 'Выдача карт игрокам';