CREATE OR REPLACE FUNCTION move_player(game_id uuid, user_id uuid, card_id integer) RETURNS void LANGUAGE 'plpgsql' AS $$
DECLARE -- Игрок
  player_id uuid;
-- Номер игрока
numb_player integer;
-- Кто в игре делает ход
current_whose_turn integer;
-- Временная переменная
number_tmp integer;
-- Номер нового хода
new_number_step integer;
state_attack boolean;
-- Кто сейчас ходит картами?
whose_move integer;
BEGIN
/**
 Получить id игрока, номер игрока, инфо об игре
 **/
SELECT INTO current_whose_turn,
  state_attack,
  numb_player,
  player_id whose_turn,
  attack,
  number_player,
  id_player
FROM game_view
WHERE id_game = game_id
  AND id_user = user_id;
-- Если игрок не найден, значит ошибка в параметрах:
IF NOT FOUND THEN RAISE EXCEPTION 'Invalid parameters';
END IF;
-- Вычисление: Кто из двух игроков сейчас ходит
CASE
  WHEN state_attack = TRUE THEN whose_move := current_whose_turn;
WHEN state_attack = FALSE
AND current_whose_turn = 1 THEN whose_move := 2;
ELSE whose_move := 1;
END CASE
;
-- Если не совпадает "кто сейчас ходит" и "текущий игрок", то ошибка
IF whose_move <> numb_player THEN RAISE EXCEPTION 'The player does not have move';
END IF;
-- Проверка, что у игрока есть такая карта
SELECT count(*) INTO number_tmp
FROM player_card
WHERE id_player = player_id
  AND id_card = card_id;
IF number_tmp = 0 THEN RAISE EXCEPTION 'The player does not have this card';
END IF;
/**
 Игрок атакует
 **/
IF state_attack THEN PERFORM player_turn(game_id, player_id, card_id);
/**
 Игрок защищается
 **/
ELSE PERFORM player_answer(game_id, player_id, card_id);
END IF;
END;
$$;