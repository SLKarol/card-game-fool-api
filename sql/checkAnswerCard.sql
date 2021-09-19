CREATE
OR REPLACE FUNCTION check_answer_card(card1 INT, card2 INT, game_id uuid) RETURNS INT LANGUAGE 'plpgsql' AS $BODY$
DECLARE
  suit1 INT;

trump INT;

BEGIN
  /** Получить данные по картам **/
  SELECT
    trump_card INTO trump
  FROM
    game
  WHERE
    game.id_game = game_id;

-- Если масти одинаковые:
IF (card1 -1) / 9 = (card2 -1) / 9
AND (card1 -1) % 9 < (card2 -1) % 9 THEN RETURN 1;

END IF;

-- Если у карты козырная масть:
IF card2 / 9 = trump / 9 THEN RETURN 1;

END IF;

RETURN 0;

END;

$BODY$;

COMMENT ON FUNCTION check_answer_card(INT, INT, uuid) IS 'Можно ли картой1 отбивать карту2 в игре_ид?';