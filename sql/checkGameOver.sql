CREATE
OR REPLACE FUNCTION check_game_over(game_id uuid) RETURNS INTEGER AS $$
DECLARE
  -- Сколько карт в колоде
  count_game_card INT;

-- Количество карт у игрока1
player1_cards INT;

-- Количество карт у игрока2
player2_cards INT;

BEGIN
  SELECT
    COUNT(*) INTO count_game_card
  FROM
    game_card
  WHERE
    id_game = game_id;

IF count_game_card > 0 THEN RETURN 0;

END IF;

SELECT
  COUNT(*) INTO player1_cards
FROM
  cards_in_hands
WHERE
  id_game = game_id
  AND number_player = 1;

SELECT
  COUNT(*) INTO player2_cards
FROM
  cards_in_hands
WHERE
  id_game = game_id
  AND number_player = 2;

IF player1_cards > 0
AND player1_cards > 0 THEN RETURN 0;

END IF;

-- Игра окончена, записать результаты в таблицу
IF player1_cards = 0 THEN
UPDATE
  users
SET
  wins = wins + 1
WHERE
  id_user IN (
    SELECT
      id_user
    FROM
      game_view
    WHERE
      id_game = game_id
      AND number_player = 1
  );

END IF;

IF player2_cards = 0 THEN
UPDATE
  users
SET
  wins = wins + 1
WHERE
  id_user IN (
    SELECT
      id_user
    FROM
      game_view
    WHERE
      id_game = game_id
      AND number_player = 2
  );

END IF;

-- Обновить данные об игре
UPDATE
  game
SET
  whose_turn = NULL
WHERE
  id_game = game_id;

RETURN 1;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION check_game_over(uuid) IS 'Проверка на то, что конец игры';