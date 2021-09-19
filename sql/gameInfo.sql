CREATE OR REPLACE FUNCTION game_info(game_id uuid) RETURNS json LANGUAGE 'sql' AS $function$
SELECT to_jsonb(g)
FROM (
    SELECT id_game as id,
      game.trump_card as "trumpCard",
      whose_turn as "whoseTurn",
      created_at as "createdAt",
      updated_at as "updatedAt",
      number_turn as "numberTurn"
    FROM game
    WHERE id_game = game_id
  ) g $function$;
COMMENT ON FUNCTION game_info(uuid) IS 'Информация об игре';