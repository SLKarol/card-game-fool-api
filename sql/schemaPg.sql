CREATE FUNCTION check_answer_card(card1 INTEGER, card2 INTEGER, game_id uuid) RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE
  suit1 INT;

trump INT;

BEGIN
  /** Получить данные по картам **/
  SELECT
    trump_card INTO trump
  FROM
    game
  WHERE
    game.id_game = game_id;

-- Если масти одинаковые:
IF (card1 -1) / 9 = (card2 -1) / 9
AND (card1 -1) % 9 < (card2 -1) % 9 THEN RETURN 1;

END IF;

-- Если у карты козырная масть:
IF card2 / 9 = trump / 9 THEN RETURN 1;

END IF;

RETURN 0;

END;

$$;

COMMENT ON FUNCTION check_answer_card(card1 INTEGER, card2 INTEGER, game_id uuid) IS 'Можно ли картой1 отбивать карту2 в игре_ид?';

CREATE FUNCTION check_game_over(game_id uuid) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  -- Сколько карт в колоде
  count_game_card INT;

-- Количество карт у игрока1
player1_cards INT;

-- Количество карт у игрока2
player2_cards INT;

BEGIN
  SELECT
    COUNT(*) INTO count_game_card
  FROM
    game_card
  WHERE
    id_game = game_id;

IF count_game_card > 0 THEN RETURN FALSE;

END IF;

SELECT
  COUNT(*) INTO player1_cards
FROM
  cards_in_hands
WHERE
  id_game = game_id
  AND number_player = 1;

SELECT
  COUNT(*) INTO player2_cards
FROM
  cards_in_hands
WHERE
  id_game = game_id
  AND number_player = 2;

IF player1_cards > 0
AND player1_cards > 0 THEN RETURN FALSE;

END IF;

-- Игра окончена, записать результаты в таблицу
IF player1_cards = 0 THEN
UPDATE
  users
SET
  wins = wins + 1
WHERE
  id_user IN (
    SELECT
      id_user
    FROM
      game_view
    WHERE
      id_game = game_id
      AND number_player = 1
  );

END IF;

IF player2_cards = 0 THEN
UPDATE
  users
SET
  wins = wins + 1
WHERE
  id_user IN (
    SELECT
      id_user
    FROM
      game_view
    WHERE
      id_game = game_id
      AND number_player = 2
  );

END IF;

RETURN TRUE;

END;

$$;

COMMENT ON FUNCTION check_game_over(game_id uuid) IS 'Проверка на то, что конец игры';

CREATE FUNCTION fail_defence(game_id uuid, user_id uuid) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  player_id uuid;

/* Кто в игре делает ход */
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Номер игрока
numb_player INTEGER;

BEGIN
  SELECT
    INTO current_whose_turn,
    state_attack,
    player_id whose_turn,
    CASE
      WHEN attack = TRUE THEN 1
      ELSE 0
    END AS i_attack,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND attack = FALSE
    AND id_user = user_id
    AND whose_turn <> number_player;

IF NOT FOUND
OR state_attack = 1
AND numb_player = current_whose_turn THEN RAISE
EXCEPTION
  'Player cant do it';

END IF;

-- Если не будешь отбиваться, значит забираешь карты со стола
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player_id,
  id_card
FROM
  cards_in_table
WHERE
  id_game = game_id;

DELETE FROM
  game_table
WHERE
  id_game_table IN (
    SELECT
      id_game_table
    FROM
      cards_in_table
    WHERE
      id_game = game_id
  );

-- Сдать карты
PERFORM set_add_cards(game_id);

-- Обновить данные об игре:
-- attack=true, updateAt=now, номер хода++
UPDATE
  game
SET
  attack = TRUE,
  number_turn = number_turn + 1,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END;

$$;

CREATE FUNCTION finish_attack(game_id uuid, user_id uuid) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  player_id uuid;

-- Номер игрока
numb_player INTEGER;

-- Кто в игре делает ход
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Кто сейчас ходит картами?
whose_move INTEGER;

-- Кто будет ходить
new_whose_move INTEGER;

BEGIN
  SELECT
    INTO current_whose_turn,
    state_attack,
    numb_player,
    player_id whose_turn,
    CASE
      WHEN attack = TRUE THEN 1
      ELSE 0
    END AS i_attack,
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

IF state_attack = 1
AND numb_player = current_whose_turn THEN
UPDATE
  game
SET
  attack = FALSE,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END IF;

RETURN FALSE;

END $$;

COMMENT ON FUNCTION finish_attack(game_id uuid, user_id uuid) IS 'Конец хода';

CREATE FUNCTION finish_turn(game_id uuid, user_id uuid) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  player_id uuid;

/* Кто в игре делает ход */
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Сколько карт в колоде
count_game_card INT;

-- Временно1
i_tmp INT;

BEGIN
  SELECT
    INTO current_whose_turn,
    state_attack,
    player_id whose_turn,
    CASE
      WHEN attack = TRUE THEN 1
      ELSE 0
    END AS i_attack,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND id_user = user_id
    AND whose_turn = number_player;

IF NOT FOUND
OR state_attack = 0 THEN RAISE
EXCEPTION
  'Player cant do it';

END IF;

-- В i_tmp записшется 1, значит у каждого игрока одинаковое количество карт и игроков 2
SELECT
  1 INTO i_tmp
FROM
  (
    SELECT
      id_player,
      COUNT(1) cnt
    FROM
      cards_in_table
    WHERE
      id_game = game_id
    GROUP BY
      id_player
  ) cp
HAVING
  COUNT(DISTINCT cnt) = 1 -- у каждого игрока одинаковое количество карт
  AND COUNT(DISTINCT id_player) > 1 -- игроков больше одного
;

SELECT
  COUNT(*) INTO count_game_card
FROM
  game_card
WHERE
  id_game = game_id;

-- ! Если count_game_card=0, то проверить кто выиграл. Опять же- сделать RETURN
-- Если игрок атакует...
IF state_attack = 1
AND i_tmp = 1
/* Сдать карты */
THEN PERFORM set_add_cards(game_id);

-- Передать атаку другому игроку
CASE
  WHEN current_whose_turn = 1 THEN current_whose_turn := 2;

ELSE current_whose_turn := 1;

END CASE
;

UPDATE
  game
SET
  number_turn = number_turn + 1,
  updated_at = now(),
  whose_turn = current_whose_turn
WHERE
  id_game = game_id;

-- Почистить игровую таблицу
DELETE FROM
  game_table
WHERE
  id_player IN (
    SELECT
      id_player
    FROM
      player
    WHERE
      id_game = game_id
  );

RETURN TRUE;

END IF;

END;

$$;

CREATE FUNCTION first_no_answer_card(
  game_id uuid,
  OUT numb_step INTEGER,
  OUT card INTEGER
) RETURNS RECORD LANGUAGE plpgsql AS $$
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

$$;

CREATE FUNCTION first_no_answer_card(
  game_id uuid,
  player_id uuid,
  OUT numb_step INTEGER,
  OUT card INTEGER
) RETURNS RECORD LANGUAGE plpgsql AS $$
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
        id_game = '88a9a6bf-94ee-4e72-8ed6-7f288603e539'
      GROUP BY
        numb_card
      ORDER BY
        cnt,
        numb_card
    ) crds,
    cards_in_table
  WHERE
    cards_in_table.id_game = '88a9a6bf-94ee-4e72-8ed6-7f288603e539'
    AND cards_in_table.numb_card = crds.numb_card
    AND crds.cnt = 1
  LIMIT
    1;

IF NOT FOUND THEN RAISE
EXCEPTION
  'Player cannot do answer';

END IF;

END;

$$;

COMMENT ON FUNCTION first_no_answer_card(
  game_id uuid,
  player_id uuid,
  OUT numb_step INTEGER,
  OUT card INTEGER
) IS 'Вернуть номер и значение первой неотвеченной карты';

CREATE FUNCTION game_info(game_id uuid) RETURNS json LANGUAGE SQL AS $$
SELECT
  to_jsonb(g)
FROM
  (
    SELECT
      id_game AS id,
      game.trump_card AS "trumpCard",
      whose_turn AS "whoseTurn",
      created_at AS "createdAt",
      updated_at AS "updatedAt",
      number_turn AS "numberTurn"
    FROM
      game
    WHERE
      id_game = game_id
  ) g $$;

COMMENT ON FUNCTION game_info(game_id uuid) IS 'Информация об игре';

CREATE FUNCTION game_table_json(game_id uuid) RETURNS json LANGUAGE SQL AS $$ --SELECT to_jsonb(res) AS game_info
--FROM (
SELECT
  array_to_json(array_agg(to_jsonb(t))) table_game
FROM
  (
    SELECT
      id_player,
      numb_card,
      id_card,
      id_suit,
      card_value
    FROM
      cards_in_table
    WHERE
      cards_in_table.id_game = game_id
    ORDER BY
      numb_card,
      number_player
  ) t --  ) res 
  $$;

COMMENT ON FUNCTION game_table_json(game_id uuid) IS 'Вывести игровую таблицу в JSON';

CREATE FUNCTION game_table_json(game_id uuid, turn INTEGER) RETURNS json LANGUAGE SQL AS $$
SELECT
  array_to_json(array_agg(to_jsonb(t))) table_game
FROM
  (
    SELECT
      id_player,
      numb_card,
      id_card,
      id_suit,
      card_value
    FROM
      cards_in_table
    WHERE
      cards_in_table.id_game = game_id
      AND number_turn = turn
    ORDER BY
      numb_card,
      number_player
  ) t $$;

CREATE FUNCTION min_no_answer_card(game_id uuid) RETURNS INTEGER LANGUAGE plpgsql AS $$ BEGIN
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

$$;

COMMENT ON FUNCTION min_no_answer_card(game_id uuid) IS 'Вернуть количество неотвеченных карт';

CREATE FUNCTION move_player(game_id uuid, user_id uuid, card_id INTEGER) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  -- Игрок
  player_id uuid;

-- Номер игрока
numb_player INTEGER;

-- Кто в игре делает ход
current_whose_turn INTEGER;

-- Временная переменная
number_tmp INTEGER;

-- Номер нового хода
new_number_step INTEGER;

state_attack BOOLEAN;

-- Кто сейчас ходит картами?
whose_move INTEGER;

BEGIN
  /**
   Получить id игрока, номер игрока, инфо об игре
   **/
  SELECT
    INTO current_whose_turn,
    state_attack,
    numb_player,
    player_id whose_turn,
    attack,
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

-- Вычисление: Кто из двух игроков сейчас ходит
CASE
  WHEN state_attack = TRUE THEN whose_move := current_whose_turn;

WHEN state_attack = FALSE
AND current_whose_turn = 1 THEN whose_move := 2;

ELSE whose_move := 1;

END CASE
;

-- Если не совпадает "кто сейчас ходит" и "текущий игрок", то ошибка
IF whose_move <> numb_player THEN RAISE
EXCEPTION
  'The player does not have move';

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
IF state_attack THEN PERFORM player_turn(game_id, player_id, card_id);

/**
 Игрок защищается
 **/
ELSE PERFORM player_answer(game_id, player_id, card_id);

END IF;

END;

$$;

CREATE FUNCTION player_answer(game_id uuid, player_id uuid, card_id INTEGER) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  /** Текущий ход **/
  current_step INT;

-- Атакующая карта
card_attack INT;

-- Может отбиваться?
can_doit INT;

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

-- Если 0, значит ход переходит нападающему
IF can_doit = 0 THEN
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

$$;

COMMENT ON FUNCTION player_answer(game_id uuid, player_id uuid, card_id INTEGER) IS 'Ход игрока- игрок отвечает';

CREATE FUNCTION player_turn(game_id uuid, player_id uuid, card_id INTEGER) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  /** Временная переменная */
  number_tmp INTEGER;

/** Номер хода */
new_number_step INTEGER;

BEGIN
  SELECT
    1 + COUNT(*) INTO new_number_step
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
  COUNT(*) INTO number_tmp
FROM
  cards_in_hands
WHERE
  id_game = game_id
  AND id_player <> player_id;

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

$$;

COMMENT ON FUNCTION player_turn(game_id uuid, player_id uuid, card_id INTEGER) IS 'Ход игрока- игрок наступает';

CREATE FUNCTION select_min_card_by_suit(player uuid, suit INTEGER) RETURNS INTEGER LANGUAGE plpgsql AS $$ BEGIN
  RETURN (
    SELECT
      MIN(player_card.id_card)
    FROM
      player_card,
      playing_card
    WHERE
      id_player = player
      AND playing_card.id_card = player_card.id_card
      AND id_suit = suit
  );

END;

$$;

COMMENT ON FUNCTION select_min_card_by_suit(player uuid, suit INTEGER) IS 'Получить все карты игрока определённой масти и из них выбрать нименьшую:';

CREATE FUNCTION set_add_cards(game_id uuid) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  /* Игрок */
  player_in_game RECORD;

/* Сколько карт дать */
need_cnt_cards INT;

BEGIN
  FOR player_in_game IN
  SELECT
    whose_turn = number_player AS current_player,
    id_player
  FROM
    game_view
  WHERE
    id_game = game_id
  ORDER BY
    current_player DESC,
    number_player
  LOOP
  SELECT
    6 - COUNT(*) INTO need_cnt_cards
  FROM
    player_card
  WHERE
    id_player = player_in_game.id_player;

IF (need_cnt_cards > 0) THEN
/* Сдать игроку need_cnt_cards из колоды */
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player_in_game.id_player,
  id_card
FROM
  game_card
WHERE
  id_game = game_id
ORDER BY
  id_game_card
LIMIT
  need_cnt_cards;

-- Удалить из колоды
DELETE FROM
  game_card
WHERE
  id_game_card IN (
    SELECT
      id_game_card
    FROM
      game_card
    WHERE
      id_game = game_id
    ORDER BY
      id_game_card
    LIMIT
      need_cnt_cards
  );

END IF;

END
LOOP
;

RETURN TRUE;

END;

$$;

CREATE FUNCTION start_game(player1 uuid, player2 uuid DEFAULT NULL :: uuid) RETURNS json LANGUAGE plpgsql AS $$
DECLARE
  new_game_id uuid = uuid_generate_v4();

player1_id uuid;

player2_id uuid;

new_trump_card INTEGER;

new_suit INTEGER;

who_new_turn INTEGER;

BEGIN
  /********************************
   Задать начальные условия игры.
   Чтобы не было ошибок с null, козырную карту записать 1
   ********************************/
  INSERT INTO
    game(id_game, trump_card)
  VALUES
    (new_game_id, 1);

-- Перемешать карты в колоде и записать это в game_card 
INSERT INTO
  game_card (id_game, id_card)
SELECT
  new_game_id,
  id_card
FROM
  playing_card
ORDER BY
  random();

-- Создать первого игрока
INSERT INTO
  player (id_game, id_user)
VALUES
  (new_game_id, player1) RETURNING id_player INTO player1_id;

-- Создать второго игрока
-- Если он не null, значит он не бот
IF player2 IS NOT NULL THEN
INSERT INTO
  player (id_game, id_user, number_player)
VALUES
  (new_game_id, player2, 2) RETURNING id_player INTO player2_id;

-- Если второй игрок null, значит он бот
ELSE
INSERT INTO
  player (id_game, id_user, number_player, robot)
VALUES
  (new_game_id, player1, 2, TRUE) RETURNING id_player INTO player2_id;

END IF;

-- Раздать карты первому игроку
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player1_id,
  id_card
FROM
  game_card
WHERE
  id_game = new_game_id
ORDER BY
  id_game_card
LIMIT
  6;

-- Раздать карты второму игроку
INSERT INTO
  player_card (id_player, id_card)
SELECT
  player2_id,
  id_card
FROM
  game_card
WHERE
  id_game = new_game_id
ORDER BY
  id_game_card
LIMIT
  6 OFFSET 6;

DELETE FROM
  game_card
WHERE
  id_game_card IN (
    SELECT
      id_game_card
    FROM
      game_card
    WHERE
      id_game = new_game_id
    ORDER BY
      id_game_card
    LIMIT
      12
  );

-- Выбрать козырную карту из колоды
SELECT
  id_card INTO new_trump_card
FROM
  game_card
WHERE
  id_game = new_game_id
ORDER BY
  id_game_card DESC
LIMIT
  1;

-- Записать козырную карту
UPDATE
  game
SET
  trump_card = new_trump_card
WHERE
  id_game = new_game_id;

-- Запомнить козырь
SELECT
  id_suit INTO new_suit
FROM
  playing_card
WHERE
  playing_card.id_card = new_trump_card;

-- Выбрать игрока с наименьшим козырем
SELECT
  y.number_player INTO who_new_turn
FROM
  (
    SELECT
      select_min_card_by_suit(id_player, new_suit) AS f,
      number_player
    FROM
      player
    WHERE
      id_game = new_game_id
    ORDER BY
      f
  ) y
LIMIT
  1;

IF who_new_turn = NULL THEN who_new_turn := 1;

END IF;

UPDATE
  game
SET
  whose_turn = who_new_turn
WHERE
  id_game = new_game_id;

-- Результат создания игры
RETURN (
  SELECT
    game_info(new_game_id)
);

END;

$$;

COMMENT ON FUNCTION start_game(player1 uuid, player2 uuid) IS 'Начинает игру с параметрами:
* ID первого игрока
* ID второго игрока
';

CREATE FUNCTION toggle_step(game_id uuid) RETURNS json LANGUAGE plpgsql AS $$
DECLARE
  numb_player INTEGER;

BEGIN
  SELECT
    number_player INTO numb_player
  FROM
    player
    INNER JOIN game ON game.id_game = player.id_game
  WHERE
    player.id_game = game_id
    AND number_player > whose_turn
  LIMIT
    1;

IF NOT FOUND THEN numb_player := 1;

END IF;

-- Обновить таблицу игра
UPDATE
  game
SET
  whose_turn = numb_player,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN (
  SELECT
    game_info(game_id)
);

END;

$$;

COMMENT ON FUNCTION toggle_step(game_id uuid) IS 'Задаёт конец хода: Переход к другому игроку';

SET
  default_tablespace = '';

SET
  default_table_access_method = HEAP;

CREATE TABLE player (
  id_player uuid DEFAULT uuid_generate_v4() NOT NULL,
  id_game uuid,
  id_user uuid,
  robot BOOLEAN DEFAULT FALSE NOT NULL,
  number_player INTEGER DEFAULT 1 NOT NULL
);

COMMENT ON TABLE player IS 'Игрок в игре';

CREATE TABLE player_card (
  id_player_card uuid DEFAULT uuid_generate_v4() NOT NULL,
  id_player uuid,
  id_card INTEGER
);

COMMENT ON TABLE player_card IS 'Карты у игрока в руках';

CREATE TABLE playing_card (
  id_card INTEGER NOT NULL,
  id_suit INTEGER,
  card_value INTEGER NOT NULL
);

COMMENT ON TABLE playing_card IS 'Игральная карта';

CREATE VIEW cards_in_hands AS
SELECT
  player.id_game,
  player.id_user,
  player.id_player,
  player.number_player,
  player_card.id_card,
  playing_card.id_suit,
  playing_card.card_value
FROM
  (
    (
      player
      JOIN player_card ON ((player.id_player = player_card.id_player))
    )
    JOIN playing_card ON ((playing_card.id_card = player_card.id_card))
  );

COMMENT ON VIEW cards_in_hands IS 'Карты у игрока';

CREATE TABLE game (
  id_game uuid DEFAULT uuid_generate_v4() NOT NULL,
  trump_card INTEGER,
  whose_turn INTEGER,
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  number_turn INTEGER DEFAULT 1 NOT NULL,
  attack BOOLEAN DEFAULT TRUE NOT NULL
);

COMMENT ON COLUMN game.whose_turn IS 'Чей ход:
null - никто (игра не начата, игра окончена и т.п.)
1- первый игрок
2- второй игрок';

COMMENT ON COLUMN game.number_turn IS 'Номер хода (Может удалить?)';

COMMENT ON COLUMN game.attack IS 'Идёт нападение или защита?';

CREATE TABLE game_table (
  id_game_table uuid DEFAULT uuid_generate_v4() NOT NULL,
  id_player uuid,
  numb_card INTEGER DEFAULT 1 NOT NULL,
  id_card INTEGER,
  number_turn INTEGER DEFAULT 1 NOT NULL
);

COMMENT ON TABLE game_table IS 'Игровой стол';

COMMENT ON COLUMN game_table.numb_card IS 'Номер карты/места на игровом столе';

COMMENT ON COLUMN game_table.number_turn IS 'Номер хода';

CREATE VIEW cards_in_table AS
SELECT
  game_table.id_game_table,
  game.id_game,
  game.number_turn,
  player.id_user,
  player.id_player,
  player.number_player,
  game_table.numb_card,
  playing_card.id_card,
  playing_card.id_suit,
  playing_card.card_value
FROM
  (
    (
      (
        game
        JOIN player ON ((game.id_game = player.id_game))
      )
      JOIN game_table ON ((game_table.id_player = player.id_player))
    )
    JOIN playing_card ON ((game_table.id_card = playing_card.id_card))
  );

COMMENT ON VIEW cards_in_table IS 'Все карты на столе';

CREATE TABLE game_card (
  id_game_card INTEGER NOT NULL,
  id_game uuid,
  id_card INTEGER
);

COMMENT ON TABLE game_card IS 'Перемешанная колода карт';

CREATE SEQUENCE game_card_id_game_card_seq AS INTEGER
START WITH
  1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE game_card_id_game_card_seq OWNED BY game_card.id_game_card;

CREATE VIEW game_view AS
SELECT
  game.id_game,
  game.whose_turn,
  game.attack,
  game.trump_card,
  player.id_user,
  users.name_user,
  player.number_player,
  player.robot,
  player.id_player,
  game.created_at
FROM
  game
  JOIN player ON game.id_game = player.id_game
  JOIN users ON player.id_user = users.id_user;

CREATE SEQUENCE playing_card_id_card_seq AS INTEGER
START WITH
  1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE playing_card_id_card_seq OWNED BY playing_card.id_card;

CREATE TABLE suit (
  id_suit INTEGER NOT NULL,
  name_suit CHARACTER VARYING NOT NULL
);

COMMENT ON TABLE suit IS 'Масть карт';

CREATE SEQUENCE suit_id_suit_seq AS INTEGER
START WITH
  1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE suit_id_suit_seq OWNED BY suit.id_suit;

CREATE TABLE users (
  id_user uuid DEFAULT uuid_generate_v4() NOT NULL,
  name_user CHARACTER VARYING NOT NULL,
  email CHARACTER VARYING NOT NULL,
  password CHARACTER VARYING NOT NULL,
  wins numeric DEFAULT 0 NOT NULL
);

COMMENT ON COLUMN users.wins IS 'Количество побед';

ALTER TABLE
  ONLY game_card
ALTER COLUMN
  id_game_card
SET
  DEFAULT NEXTVAL('game_card_id_game_card_seq' :: regclass);

ALTER TABLE
  ONLY playing_card
ALTER COLUMN
  id_card
SET
  DEFAULT NEXTVAL('playing_card_id_card_seq' :: regclass);

ALTER TABLE
  ONLY suit
ALTER COLUMN
  id_suit
SET
  DEFAULT NEXTVAL('suit_id_suit_seq' :: regclass);

ALTER TABLE
  ONLY playing_card
ADD
  CONSTRAINT card_pkey PRIMARY KEY (id_card);

ALTER TABLE
  ONLY users
ADD
  CONSTRAINT email_cu UNIQUE (email);

ALTER TABLE
  ONLY game_card
ADD
  CONSTRAINT id_game_card_pkey PRIMARY KEY (id_game_card);

ALTER TABLE
  ONLY game
ADD
  CONSTRAINT id_game_pkey PRIMARY KEY (id_game);

ALTER TABLE
  ONLY game_table
ADD
  CONSTRAINT id_game_table PRIMARY KEY (id_game_table);

ALTER TABLE
  ONLY player_card
ADD
  CONSTRAINT id_player_card_pkey PRIMARY KEY (id_player_card);

ALTER TABLE
  ONLY player
ADD
  CONSTRAINT id_player_pkey PRIMARY KEY (id_player);

ALTER TABLE
  ONLY users
ADD
  CONSTRAINT id_user_pkey PRIMARY KEY (id_user);

ALTER TABLE
  ONLY users
ADD
  CONSTRAINT name_user_cu UNIQUE (name_user);

ALTER TABLE
  ONLY suit
ADD
  CONSTRAINT suit_pkey PRIMARY KEY (id_suit);

ALTER TABLE
  ONLY game_card
ADD
  CONSTRAINT game_card_id_card_fkey FOREIGN KEY (id_card) REFERENCES playing_card(id_card);

ALTER TABLE
  ONLY game_card
ADD
  CONSTRAINT game_card_id_game_fkey FOREIGN KEY (id_game) REFERENCES game(id_game) ON
DELETE
  CASCADE;

ALTER TABLE
  ONLY game_table
ADD
  CONSTRAINT game_table_id_card_fkey FOREIGN KEY (id_card) REFERENCES playing_card(id_card);

ALTER TABLE
  ONLY game_table
ADD
  CONSTRAINT game_table_id_player_fkey FOREIGN KEY (id_player) REFERENCES player(id_player) ON
DELETE
  CASCADE;

ALTER TABLE
  ONLY game
ADD
  CONSTRAINT game_trump_card_fkey FOREIGN KEY (trump_card) REFERENCES playing_card(id_card);

ALTER TABLE
  ONLY player_card
ADD
  CONSTRAINT player_card_id_card_fkey FOREIGN KEY (id_card) REFERENCES playing_card(id_card);

ALTER TABLE
  ONLY player_card
ADD
  CONSTRAINT player_card_id_player_fkey FOREIGN KEY (id_player) REFERENCES player(id_player) ON
DELETE
  CASCADE;

ALTER TABLE
  ONLY player
ADD
  CONSTRAINT player_id_game_fkey FOREIGN KEY (id_game) REFERENCES game(id_game) ON
DELETE
  CASCADE;

ALTER TABLE
  ONLY player
ADD
  CONSTRAINT player_id_user_fkey FOREIGN KEY (id_user) REFERENCES users(id_user) ON
DELETE
  CASCADE;

ALTER TABLE
  ONLY playing_card
ADD
  CONSTRAINT playing_card_id_suit_fkey FOREIGN KEY (id_suit) REFERENCES suit(id_suit) ON
DELETE
  CASCADE;