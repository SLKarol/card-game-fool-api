CREATE
OR REPLACE FUNCTION finish_turn(game_id uuid, user_id uuid) RETURNS BOOLEAN AS $$
DECLARE
  player_id uuid;

/* Кто в игре делает ход */
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Игра окончена?
game_over INT;

-- Временно1
i_tmp INT;

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
    AND id_user = user_id
    AND whose_turn = number_player;

IF NOT FOUND
OR state_attack = 0 THEN RAISE
EXCEPTION
  'Player cant do it';

END IF;

-- В i_tmp записшется 1, значит на столе от каждого игрока одинаковое количество карт и игроков 2
SELECT
  1 INTO i_tmp
FROM
  (
    SELECT
      id_player,
      COUNT(1) cnt
    FROM
      cards_in_table
    WHERE
      id_game = game_id
    GROUP BY
      id_player
  ) cp
HAVING
  COUNT(DISTINCT cnt) = 1 -- от каждого игрока одинаковое количество карт
  AND COUNT(DISTINCT id_player) > 1 -- игроков больше одного
;

SELECT
  check_game_over(game_id) INTO game_over;

IF game_over = 0 THEN -- Если игрок атакует...
IF state_attack = 1
AND i_tmp = 1
/* Сдать карты */
THEN PERFORM set_add_cards(game_id);

-- Передать атаку другому игроку
CASE
  WHEN current_whose_turn = 1 THEN current_whose_turn := 2;

ELSE current_whose_turn := 1;

END CASE
;

UPDATE
  game
SET
  number_turn = number_turn + 1,
  updated_at = now(),
  whose_turn = current_whose_turn
WHERE
  id_game = game_id;

-- Почистить игровую таблицу
DELETE FROM
  game_table
WHERE
  id_player IN (
    SELECT
      id_player
    FROM
      player
    WHERE
      id_game = game_id
  );

RETURN TRUE;

END IF;

END IF;

RETURN FALSE;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION finish_attack(uuid, uuid) IS 'Конец хода';