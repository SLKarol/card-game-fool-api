-- DROP FUNCTION IF EXISTS game_table_json;
CREATE OR REPLACE FUNCTION game_table_json(game_id uuid, turn integer) RETURNS json LANGUAGE sql AS $function$
SELECT array_to_json(array_agg(to_jsonb(t))) table_game
FROM (
    SELECT id_player,
      numb_card,
      id_card,
      id_suit,
      card_value
    FROM cards_in_table
    WHERE cards_in_table.id_game = game_id
      AND number_turn = turn
    ORDER BY numb_card,
      number_player
  ) t $function$;
COMMENT ON FUNCTION game_table_json(uuid) IS 'Вывести игровую таблицу в JSON';