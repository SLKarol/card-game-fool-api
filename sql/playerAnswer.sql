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
   Получить номер на доске и номер карты, на который делается ответ:
   Берётся минимальный неотвеченный номер хода
   */
  SELECT
    INTO current_step,
    card_attack numb_step,
    card
  FROM
    first_no_answer_card(game_id);

-- Можно ли картой1 отбивать карту2?
SELECT
  check_answer_card(card_attack, card_id, game_id) INTO can_doit;

IF can_doit = 1 THEN -- Перенести карту на стол
INSERT INTO
  game_table(id_player, numb_card, id_card)
VALUES
  (player_id, current_step, card_id);

END IF;

-- Удалить из рук игрока эту карту
DELETE FROM
  player_card
WHERE
  id_player = player_id
  AND id_card = card_id;

END;

$BODY$;

COMMENT ON FUNCTION player_answer(uuid, uuid, INTEGER) IS 'Ход игрока- игрок отвечает';