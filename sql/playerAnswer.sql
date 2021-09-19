CREATE
OR REPLACE FUNCTION player_answer(
  game_id uuid,
  player_id uuid,
  card_id INTEGER
) RETURNS VOID LANGUAGE 'plpgsql' AS $BODY$
DECLARE
  /** Текущий ход **/
  current_step INT;

-- Атакующая карта
card_attack INT;

-- Может отбиваться?
can_doit INT;

-- Игра окончена?
game_over INT;

BEGIN
  /*
   Получить номер хода, и номер карты, на который делается ответ:
   Берётся минимальный неотвеченный номер хода
   */
  SELECT
    INTO current_step,
    card_attack numb_step,
    card
  FROM
    first_no_answer_card(game_id);

-- Можно ли картой1 отбивать карту2 в игре_ид?
SELECT
  check_answer_card(card_attack, card_id, game_id) INTO can_doit;

IF can_doit = 1 THEN -- Перенести карту на стол
INSERT INTO
  game_table(id_player, numb_card, id_card)
VALUES
  (player_id, current_step, card_id);

-- Удалить из рук игрока эту карту
DELETE FROM
  player_card
WHERE
  id_player = player_id
  AND id_card = card_id;

-- Сколько осталось не отбитых карт?
SELECT
  min_no_answer_card(game_id) INTO can_doit;

-- Проверить: Есть ли карты в руках для отбивки?
-- После этой проверки сразу же: Вычисление, кто победил?
SELECT
  check_game_over (game_id) INTO game_over;

-- Если 0, значит ход переходит нападающему
IF can_doit = 0
AND game_over = 0 THEN
UPDATE
  game
SET
  attack = TRUE,
  updated_at = now()
WHERE
  id_game = game_id;

END IF;

ELSE RAISE
EXCEPTION
  'Player cant do this';

END IF;

END;

$BODY$;

COMMENT ON FUNCTION player_answer(uuid, uuid, INTEGER) IS 'Ход игрока- игрок отвечает';