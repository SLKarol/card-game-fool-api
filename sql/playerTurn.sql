CREATE
OR REPLACE FUNCTION player_turn(game_id uuid, player_id uuid, card_id INTEGER) RETURNS VOID LANGUAGE plpgsql AS $function$
DECLARE
  /** Временная переменная */
  number_tmp INTEGER;

/** Номер хода */
new_number_step INTEGER;

BEGIN
  SELECT
    1 + COALESCE(MAX(numb_card), 0) INTO new_number_step
  FROM
    cards_in_table
  WHERE
    id_game = game_id;

-- Если никаких карт не было, то можешь ходить чем хочешь
IF new_number_step = 1 THEN
INSERT INTO
  game_table(id_player, numb_card, id_card)
VALUES
  (player_id, new_number_step, card_id);

ELSE -- Если есть карты, то нужно проверить- можно ли ходить таким номером?
-- а: Получить номер карты
SELECT
  card_value INTO number_tmp
FROM
  playing_card
WHERE
  id_card = card_id;

-- b: Этот номер есть на игровом столе?
SELECT
  COUNT(*) INTO number_tmp
FROM
  cards_in_table
WHERE
  cards_in_table.id_game = game_id
  AND cards_in_table.card_value = number_tmp;

IF number_tmp = 0 THEN RAISE
EXCEPTION
  'It is not possible to walk with this card';

END IF;

-- C: У второго игрока хватит карт отбить?
SELECT
  check_have_card_answer(game_id, player_id) INTO number_tmp;

IF number_tmp = 0 THEN RAISE
EXCEPTION
  'The enemy has no cards';

END IF;

-- Перенести карту на стол
INSERT INTO
  game_table(id_player, numb_card, id_card)
VALUES
  (player_id, new_number_step, card_id);

END IF;

-- Удалить из рук игрока эту карту
DELETE FROM
  player_card
WHERE
  id_player = player_id
  AND id_card = card_id;

END;

$function$;