CREATE
OR REPLACE FUNCTION check_game_over(game_id uuid) RETURNS INTEGER AS $$
DECLARE
  -- Сколько карт в колоде
  count_game_card INT;

-- Количество карт у игрока1
player1_cards INT;

-- Количество карт у игрока2
player2_cards INT;

-- Есть ли 
BEGIN
  -- Если нет записей в таблице рекордов, значит игру требуется проверить на то, что она окончена
  IF NOT EXISTS (
    SELECT
      *
    FROM
      score
    WHERE
      id_game = game_id
  ) THEN
  SELECT
    COUNT(*) INTO count_game_card
  FROM
    game_card
  WHERE
    id_game = game_id;

-- Если есть карты в колоде, значит игра ещё идёт
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
AND player2_cards > 0 THEN RETURN 0;

END IF;

-- Игра окончена, записать результаты в таблицу рекордов
IF player1_cards = 0 THEN
INSERT INTO
  score (id_game, id_user)
SELECT
  game_id,
  id_user
FROM
  game_view
WHERE
  id_game = game_id
  AND number_player = 1;

END IF;

IF player2_cards = 0 THEN
INSERT INTO
  score (id_game, id_user)
SELECT
  game_id,
  id_user
FROM
  game_view
WHERE
  id_game = game_id
  AND number_player = 2;

END IF;

-- Обновить данные об игре
UPDATE
  game
SET
  whose_turn = NULL
WHERE
  id_game = game_id;

RETURN 1;

-- Иначе, вернуть 1- игра окончена
ELSE RETURN 1;

END IF;

END;

$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION check_game_over(uuid) IS 'Проверка на то, что конец игры';