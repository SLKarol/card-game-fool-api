CREATE
OR REPLACE FUNCTION check_have_card_answer(game_id uuid, player_id uuid) RETURNS INT LANGUAGE 'plpgsql' AS $BODY$
DECLARE
  count_places_table INT;

count_answer_places INT;

count_opponent_card INT;

BEGIN
  -- Сколько всего карт (мест) на карточном столе?
  SELECT
    COUNT(*) INTO count_places_table
  FROM
    game_table
  WHERE
    id_player = player_id;

-- Сколько всего карт отбил?
SELECT
  COUNT(*) INTO count_answer_places
FROM
  game_table
WHERE
  id_player <> player_id;

-- Сколько карт у игрока в руках?
SELECT
  COUNT(*) INTO count_opponent_card
FROM
  player_card
WHERE
  id_player = player_id;

-- Если не отбитых карт меньше или равно 
IF (count_places_table - count_answer_places) < count_opponent_card THEN RETURN 1;

END IF;

RETURN 0;

END;

$BODY$;

COMMENT ON FUNCTION check_have_card_answer(uuid, uuid) IS 'Хватает ли карт у игрока отбиться?';