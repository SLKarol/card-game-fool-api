CREATE
OR REPLACE FUNCTION min_no_answer_card(game_id uuid) RETURNS INT LANGUAGE 'plpgsql' AS $function$ BEGIN
  RETURN (
    SELECT
      COUNT(*)
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
        LIMIT
          1
      ) C
    WHERE
      C .cnt = 1
  );

END;

$function$;

COMMENT ON FUNCTION min_no_answer_card(uuid) IS 'Вернуть количество неотвеченных карт';