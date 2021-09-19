CREATE
OR REPLACE FUNCTION fail_defence(game_id uuid, user_id uuid) RETURNS BOOLEAN AS $$
DECLARE
  player_id uuid;

/* Кто в игре делает ход */
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Номер игрока
numb_player INTEGER;

BEGIN
  SELECT
    INTO current_whose_turn,
    state_attack,
    player_id whose_turn,
    CASE
      WHEN attack = TRUE THEN 1
      ELSE 0
    END AS i_attack,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND attack = FALSE
    AND id_user = user_id
    AND whose_turn <> number_player;

IF NOT FOUND
OR state_attack = 1
AND numb_player = current_whose_turn THEN RAISE
EXCEPTION
  'Player cant do it';

END IF;

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
-- attack=true, updateAt=now, номер хода++
UPDATE
  game
SET
  attack = TRUE,
  number_turn = number_turn + 1,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION fail_defence(uuid, uuid) IS 'Игрок не смог отбить';