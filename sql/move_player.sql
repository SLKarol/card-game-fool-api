CREATE
OR REPLACE FUNCTION move_player(game_id uuid, user_id uuid, card_id INTEGER) RETURNS VOID LANGUAGE 'plpgsql' AS $$
DECLARE
  -- Игрок
  player_id uuid;

-- Номер игрока
numb_player INTEGER;

-- Кто в игре делает ход
current_whose_turn INTEGER;

-- Временная переменная
number_tmp INTEGER;

BEGIN
  /**
   Получить id игрока, номер игрока, инфо об игре
   **/
  SELECT
    INTO current_whose_turn,
    numb_player,
    player_id whose_turn,
    number_player,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND id_user = user_id;

-- Если игрок не найден, значит ошибка в параметрах:
IF NOT FOUND THEN RAISE
EXCEPTION
  'Invalid parameters';

END IF;

-- Проверка, что у игрока есть такая карта
SELECT
  COUNT(*) INTO number_tmp
FROM
  player_card
WHERE
  id_player = player_id
  AND id_card = card_id;

IF number_tmp = 0 THEN RAISE
EXCEPTION
  'The player does not have this card';

END IF;

/**
 Игрок атакует
 **/
IF current_whose_turn = numb_player THEN PERFORM player_turn(game_id, player_id, card_id);

/**
 Игрок защищается
 **/
ELSE PERFORM player_answer(game_id, player_id, card_id);

END IF;

END;

$$;