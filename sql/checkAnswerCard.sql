CREATE
OR REPLACE FUNCTION check_answer_card(card1 INT, card2 INT, game_id uuid) RETURNS INT LANGUAGE 'plpgsql' AS $BODY$
DECLARE
  suit1 INT;

trump INT;

BEGIN
  /** Получить козырь в игре **/
  SELECT
    trump_card INTO trump
  FROM
    game
  WHERE
    game.id_game = game_id;

-- Если масть одинаковая и значение отбиваемой карты больше, то можно отбивать:
IF (card1 -1) / 9 = (card2 -1) / 9
AND (card1 -1) % 9 < (card2 -1) % 9 THEN RETURN 1;

END IF;

-- Если отбиваюсь козырем, а нападет не козырь, то можно отбивать:
IF (card2 -1) / 9 = (trump -1) / 9
AND (card1 -1) / 9 <> (trump -1) / 9 THEN RETURN 1;

END IF;

RETURN 0;

END;

$BODY$;

COMMENT ON FUNCTION check_answer_card(INT, INT, uuid) IS 'Можно ли картой1 отбивать карту2 в игре_ид?';