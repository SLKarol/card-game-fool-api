CREATE
OR REPLACE FUNCTION first_no_answer_card(
  game_id uuid,
  OUT numb_step INT,
  OUT card INT
) LANGUAGE 'plpgsql' AS $function$
DECLARE
  n INTEGER;

BEGIN
  SELECT
    INTO numb_step,
    card cards_in_table.numb_card,
    id_card
  FROM
    (
      SELECT
        COUNT(numb_card) AS cnt,
        numb_card
      FROM
        cards_in_table
      WHERE
        id_game = game_id
      GROUP BY
        numb_card
      ORDER BY
        cnt,
        numb_card
    ) crds,
    cards_in_table
  WHERE
    cards_in_table.id_game = game_id
    AND cards_in_table.numb_card = crds.numb_card
    AND crds.cnt = 1
  LIMIT
    1;

IF NOT FOUND THEN RAISE
EXCEPTION
  'Player cannot do answer';

END IF;

END;

$function$;

COMMENT ON FUNCTION first_no_answer_card(uuid, uuid) IS 'Вернуть номер и значение первой неотвеченной карты';