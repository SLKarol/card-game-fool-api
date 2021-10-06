CREATE
OR REPLACE FUNCTION fail_defence(game_id uuid, user_id uuid) RETURNS BOOLEAN AS $$
DECLARE
  player_id uuid;

BEGIN
  -- Получить id_player
  SELECT
    INTO player_id id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND id_user = user_id;

-- Если не будешь отбиваться, значит забираешь карты со стола
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player_id,
  id_card
FROM
  cards_in_table
WHERE
  id_game = game_id;

DELETE FROM
  game_table
WHERE
  id_game_table IN (
    SELECT
      id_game_table
    FROM
      cards_in_table
    WHERE
      id_game = game_id
  );

-- Сдать карты
PERFORM set_add_cards(game_id);

-- Обновить данные об игре:
-- updateAt=now, номер хода++
UPDATE
  game
SET
  number_turn = number_turn + 1,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION fail_defence(uuid, uuid) IS 'Игрок не смог отбить';