CREATE OR REPLACE FUNCTION toggle_step(game_id uuid) RETURNS json LANGUAGE 'plpgsql' AS $$
DECLARE -- Номер игрока, который будет ходить
  numb_player integer;
BEGIN
SELECT number_player INTO numb_player
FROM player
  INNER JOIN game ON game.id_game = player.id_game
WHERE player.id_game = game_id
  AND number_player > whose_turn
LIMIT 1;
IF NOT FOUND THEN numb_player := 1;
-- Обновить таблицу игра
UPDATE game
SET whose_turn = numb_player,
  updated_at = now()
WHERE id_game = game_id;
RETURN (
  SELECT game_info(new_game_id)
);
END;
$$;
COMMENT ON FUNCTION toggle_step(uuid) IS 'Задаёт конец хода: Переход к другому игроку';