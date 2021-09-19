-- DROP FUNCTION finish_attack(uuid,uuid);
CREATE
OR REPLACE FUNCTION finish_attack(game_id uuid, user_id uuid) RETURNS BOOLEAN LANGUAGE 'plpgsql' AS $$
DECLARE
  player_id uuid;

-- Номер игрока
numb_player INTEGER;

-- Кто в игре делает ход
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

BEGIN
  SELECT
    INTO current_whose_turn,
    state_attack,
    numb_player,
    player_id whose_turn,
    CASE
      WHEN attack = TRUE THEN 1
      ELSE 0
    END AS i_attack,
    number_player,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND id_user = user_id;

-- Если игрок не найден, значит ошибка в параметрах:
IF NOT FOUND THEN RAISE
EXCEPTION
  'Invalid parameters';

END IF;

-- ? Проверить: Сколько карт в колоде, в руке и если всё по нулям, то проверить кто выиграл. Опять же- сделать RETURN
IF state_attack = 1
AND numb_player = current_whose_turn THEN
UPDATE
  game
SET
  attack = FALSE,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END IF;

RETURN FALSE;

END $$;

COMMENT ON FUNCTION finish_attack(uuid, uuid) IS 'Конец атаки';