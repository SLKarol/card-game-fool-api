--
-- PostgreSQL database dump
--

-- Dumped from database version 13.3
-- Dumped by pg_dump version 13.3

-- Started on 2022-01-02 12:55:33

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 3143 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 246 (class 1255 OID 42307)
-- Name: check_answer_card(integer, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_answer_card(card1 integer, card2 integer, game_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  suit1 INT;

trump INT;

BEGIN
  /** Получить козырь в игре **/
  SELECT
    trump_card INTO trump
  FROM
    game
  WHERE
    game.id_game = game_id;

-- Если масть одинаковая и значение отбиваемой карты больше, то можно отбивать:
IF (card1 -1) / 9 = (card2 -1) / 9
AND (card1 -1) % 9 < (card2 -1) % 9 THEN RETURN 1;

END IF;

-- Если отбиваюсь козырем, а нападет не козырь, то можно отбивать:
IF (card2 -1) / 9 = (trump -1) / 9
AND (card1 -1) / 9 <> (trump -1) / 9 THEN RETURN 1;

END IF;

RETURN 0;

END;

$$;


--
-- TOC entry 3144 (class 0 OID 0)
-- Dependencies: 246
-- Name: FUNCTION check_answer_card(card1 integer, card2 integer, game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.check_answer_card(card1 integer, card2 integer, game_id uuid) IS 'Можно ли картой1 отбивать карту2 в игре_ид?';


--
-- TOC entry 255 (class 1255 OID 50439)
-- Name: check_game_over(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_game_over(game_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- Сколько карт в колоде
  count_game_card INT;

-- Количество карт у игрока1
player1_cards INT;

-- Количество карт у игрока2
player2_cards INT;

-- Есть ли 
BEGIN
  -- Если нет записей в таблице рекордов, значит игру требуется проверить на то, что она окончена
  IF NOT EXISTS (
    SELECT
      *
    FROM
      score
    WHERE
      id_game = game_id
  ) THEN
  SELECT
    COUNT(*) INTO count_game_card
  FROM
    game_card
  WHERE
    id_game = game_id;

-- Если есть карты в колоде, значит игра ещё идёт
IF count_game_card > 0 THEN RETURN 0;

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
AND player2_cards > 0 THEN RETURN 0;

END IF;

-- Игра окончена, записать результаты в таблицу рекордов
IF player1_cards = 0 THEN
INSERT INTO
  score (id_game, id_user)
SELECT
  game_id,
  id_user
FROM
  game_view
WHERE
  id_game = game_id
  AND number_player = 1;

END IF;

IF player2_cards = 0 THEN
INSERT INTO
  score (id_game, id_user)
SELECT
  game_id,
  id_user
FROM
  game_view
WHERE
  id_game = game_id
  AND number_player = 2;

END IF;

-- Обновить данные об игре
UPDATE
  game
SET
  whose_turn = NULL
WHERE
  id_game = game_id;

RETURN 1;

-- Иначе, вернуть 1- игра окончена
ELSE RETURN 1;
end if;
END;

$$;


--
-- TOC entry 3145 (class 0 OID 0)
-- Dependencies: 255
-- Name: FUNCTION check_game_over(game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.check_game_over(game_id uuid) IS 'Проверка на то, что конец игры';


--
-- TOC entry 250 (class 1255 OID 66855)
-- Name: check_have_card_answer(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_have_card_answer(game_id uuid, player_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  count_places_table INT;

count_answer_places INT;

count_opponent_card INT;

BEGIN
  -- Сколько всего карт (мест) на карточном столе?
  SELECT
    COUNT(*) INTO count_places_table
  FROM
    game_table
  WHERE
    id_player = player_id;

-- Сколько всего карт отбил?
SELECT
  COUNT(*) INTO count_answer_places
FROM
  game_table
WHERE
  id_player <> player_id;

-- Сколько карт у игрока в руках?
SELECT
  COUNT(*) INTO count_opponent_card
FROM
  player_card
WHERE
  id_player = player_id;

-- Если не отбитых карт меньше или равно 
IF (count_places_table - count_answer_places) < count_opponent_card THEN RETURN 1;

END IF;

RETURN 0;

END;

$$;


--
-- TOC entry 3146 (class 0 OID 0)
-- Dependencies: 250
-- Name: FUNCTION check_have_card_answer(game_id uuid, player_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.check_have_card_answer(game_id uuid, player_id uuid) IS 'Хватает ли карт у игрока отбиться?';


--
-- TOC entry 249 (class 1255 OID 50436)
-- Name: fail_defence(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_defence(game_id uuid, user_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  player_id uuid;

BEGIN
  -- Получить id_player
  SELECT
    INTO player_id id_player
  FROM
    game_view
  WHERE
    id_game = game_id
    AND id_user = user_id;

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
-- updateAt=now, номер хода++
UPDATE
  game
SET
  number_turn = number_turn + 1,
  updated_at = now()
WHERE
  id_game = game_id;

RETURN TRUE;

END;

$$;


--
-- TOC entry 3147 (class 0 OID 0)
-- Dependencies: 249
-- Name: FUNCTION fail_defence(game_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fail_defence(game_id uuid, user_id uuid) IS 'Игрок не смог отбить';


--
-- TOC entry 248 (class 1255 OID 42295)
-- Name: finish_attack(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_attack(game_id uuid, user_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE player_id uuid;
-- Номер игрока
numb_player integer;
-- Кто в игре делает ход
current_whose_turn integer;
-- Сейчас атака?
state_attack integer;
-- Кто сейчас ходит картами?
whose_move integer;
-- Кто будет ходить
new_whose_move integer;
BEGIN
SELECT INTO current_whose_turn,
  state_attack,
  numb_player,
  player_id whose_turn,
  case when attack=TRUE then 1 else 0 end as i_attack,
  number_player,
  id_player
FROM game_view
WHERE id_game = game_id
  AND id_user = user_id;
-- Если игрок не найден, значит ошибка в параметрах:
IF NOT FOUND THEN RAISE EXCEPTION 'Invalid parameters';
END IF;

IF state_attack = 1 AND numb_player = current_whose_turn THEN
UPDATE game
SET attack = false,
  updated_at = now()
WHERE id_game = game_id;
RETURN TRUE;
END IF;
RETURN FALSE;
END $$;


--
-- TOC entry 3148 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION finish_attack(game_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.finish_attack(game_id uuid, user_id uuid) IS 'Конец хода';


--
-- TOC entry 252 (class 1255 OID 50429)
-- Name: finish_turn(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_turn(game_id uuid, user_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  player_id uuid;

/* Кто в игре делает ход */
current_whose_turn INTEGER;

-- Сейчас атака?
state_attack INTEGER;

-- Игра окончена?
game_over INT;

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

-- В i_tmp записшется 1, значит на столе от каждого игрока одинаковое количество карт и игроков 2
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
  COUNT(DISTINCT cnt) = 1 -- от каждого игрока одинаковое количество карт
  AND COUNT(DISTINCT id_player) > 1 -- игроков больше одного
;

SELECT
  check_game_over (game_id) INTO game_over;

IF game_over = 0 THEN -- Если игрок атакует...
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

END IF;

RETURN FALSE;

END;

$$;


--
-- TOC entry 245 (class 1255 OID 42317)
-- Name: first_no_answer_card(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.first_no_answer_card(game_id uuid, OUT numb_step integer, OUT card integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
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


--
-- TOC entry 243 (class 1255 OID 42300)
-- Name: first_no_answer_card(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.first_no_answer_card(game_id uuid, player_id uuid, OUT numb_step integer, OUT card integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
  n INTEGER;

BEGIN
  SELECT
    INTO numb_step,
    card cards_in_table.numb_card,id_card
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
    ) crds, cards_in_table
  WHERE
  cards_in_table.id_game='88a9a6bf-94ee-4e72-8ed6-7f288603e539' AND 
  cards_in_table.numb_card=crds.numb_card and
    crds.cnt = 1
  LIMIT
    1;

IF NOT FOUND THEN RAISE
EXCEPTION
  'Player cannot do answer';

END IF;

END;

$$;


--
-- TOC entry 3149 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION first_no_answer_card(game_id uuid, player_id uuid, OUT numb_step integer, OUT card integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.first_no_answer_card(game_id uuid, player_id uuid, OUT numb_step integer, OUT card integer) IS 'Вернуть номер и значение первой неотвеченной карты';


--
-- TOC entry 230 (class 1255 OID 42259)
-- Name: game_info(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.game_info(game_id uuid) RETURNS json
    LANGUAGE sql
    AS $$
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
  ) g $$;


--
-- TOC entry 3150 (class 0 OID 0)
-- Dependencies: 230
-- Name: FUNCTION game_info(game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.game_info(game_id uuid) IS 'Информация об игре';


--
-- TOC entry 242 (class 1255 OID 42253)
-- Name: game_table_json(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.game_table_json(game_id uuid) RETURNS json
    LANGUAGE sql
    AS $$
--SELECT to_jsonb(res) AS game_info
--FROM (
    SELECT array_to_json(array_agg(to_jsonb(t))) table_game
    FROM (
        SELECT id_player,
          numb_card,
          id_card,
          id_suit,
          card_value
        FROM cards_in_table
        WHERE cards_in_table.id_game = game_id
        ORDER BY numb_card,
          number_player
      ) t
--  ) res 
$$;


--
-- TOC entry 3151 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION game_table_json(game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.game_table_json(game_id uuid) IS 'Вывести игровую таблицу в JSON';


--
-- TOC entry 247 (class 1255 OID 42274)
-- Name: game_table_json(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.game_table_json(game_id uuid, turn integer) RETURNS json
    LANGUAGE sql
    AS $$
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
  ) t $$;


--
-- TOC entry 258 (class 1255 OID 50447)
-- Name: get_my_open_games(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_open_games(user_id uuid) RETURNS json
    LANGUAGE sql
    AS $$
SELECT
json_agg(t) games
FROM(
select id_game as "idGame", name_user as "nameUser", created_at as "createdAt"
from game_view 
where 
id_game in(select id_game from game_view where id_user=user_id)
and id_user <>user_id
order by created_at
  ) t
  ;
$$;


--
-- TOC entry 3152 (class 0 OID 0)
-- Dependencies: 258
-- Name: FUNCTION get_my_open_games(user_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_my_open_games(user_id uuid) IS 'Возвращает список открытых игр';


--
-- TOC entry 244 (class 1255 OID 42316)
-- Name: min_no_answer_card(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.min_no_answer_card(game_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$ BEGIN
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
          cnt, numb_card
        LIMIT
          1
      ) C
    WHERE
      C.cnt = 1
  );

END;

$$;


--
-- TOC entry 3153 (class 0 OID 0)
-- Dependencies: 244
-- Name: FUNCTION min_no_answer_card(game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.min_no_answer_card(game_id uuid) IS 'Вернуть количество неотвеченных карт';


--
-- TOC entry 253 (class 1255 OID 42251)
-- Name: move_player(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.move_player(game_id uuid, user_id uuid, card_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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


--
-- TOC entry 254 (class 1255 OID 42275)
-- Name: player_answer(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.player_answer(game_id uuid, player_id uuid, card_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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

ELSE RAISE
EXCEPTION
  'Player cant do this';

END IF;

-- Удалить из рук игрока эту карту
DELETE FROM
  player_card
WHERE
  id_player = player_id
  AND id_card = card_id;

END;

$$;


--
-- TOC entry 3154 (class 0 OID 0)
-- Dependencies: 254
-- Name: FUNCTION player_answer(game_id uuid, player_id uuid, card_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.player_answer(game_id uuid, player_id uuid, card_id integer) IS 'Ход игрока- игрок отвечает';


--
-- TOC entry 251 (class 1255 OID 42286)
-- Name: player_turn(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.player_turn(game_id uuid, player_id uuid, card_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  /** Временная переменная */
  number_tmp INTEGER;

/** Номер хода */
new_number_step INTEGER;

BEGIN

  SELECT
    1+coalesce(max(numb_card), 0) INTO new_number_step
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

$$;


--
-- TOC entry 3155 (class 0 OID 0)
-- Dependencies: 251
-- Name: FUNCTION player_turn(game_id uuid, player_id uuid, card_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.player_turn(game_id uuid, player_id uuid, card_id integer) IS 'Ход игрока- игрок наступает';


--
-- TOC entry 229 (class 1255 OID 42233)
-- Name: select_min_card_by_suit(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.select_min_card_by_suit(player uuid, suit integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN RETURN (
    SELECT min(player_card.id_card)
    FROM player_card,
      playing_card
    WHERE id_player = player
      and playing_card.id_card = player_card.id_card
      AND id_suit = suit
  );
END;
$$;


--
-- TOC entry 3156 (class 0 OID 0)
-- Dependencies: 229
-- Name: FUNCTION select_min_card_by_suit(player uuid, suit integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.select_min_card_by_suit(player uuid, suit integer) IS 'Получить все карты игрока определённой масти и из них выбрать нименьшую:';


--
-- TOC entry 257 (class 1255 OID 50430)
-- Name: set_add_cards(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_add_cards(game_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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


--
-- TOC entry 256 (class 1255 OID 50440)
-- Name: start_game(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.start_game(player1 uuid, player2 uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
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
RETURN new_game_id;

END;

$$;


--
-- TOC entry 3157 (class 0 OID 0)
-- Dependencies: 256
-- Name: FUNCTION start_game(player1 uuid, player2 uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.start_game(player1 uuid, player2 uuid) IS 'Начинает игру с параметрами:
* ID первого игрока
* ID второго игрока
';


--
-- TOC entry 228 (class 1255 OID 42262)
-- Name: toggle_step(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.toggle_step(game_id uuid) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  numb_player integer;
BEGIN
SELECT number_player INTO numb_player
FROM player
  INNER JOIN game ON game.id_game = player.id_game
WHERE player.id_game = game_id
  AND number_player > whose_turn
LIMIT 1;
IF NOT FOUND THEN numb_player := 1; END IF;
-- Обновить таблицу игра
UPDATE game
SET whose_turn = numb_player,
  updated_at = now()
WHERE id_game = game_id;
RETURN (
  SELECT game_info(game_id)
);
END;
$$;


--
-- TOC entry 3158 (class 0 OID 0)
-- Dependencies: 228
-- Name: FUNCTION toggle_step(game_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.toggle_step(game_id uuid) IS 'Задаёт конец хода: Переход к другому игроку';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 207 (class 1259 OID 42161)
-- Name: player; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player (
    id_player uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_game uuid,
    id_user uuid,
    robot boolean DEFAULT false NOT NULL,
    number_player integer DEFAULT 1 NOT NULL
);


--
-- TOC entry 3159 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE player; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player IS 'Игрок в игре';


--
-- TOC entry 208 (class 1259 OID 42179)
-- Name: player_card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_card (
    id_player_card uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_player uuid,
    id_card integer
);


--
-- TOC entry 3160 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE player_card; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.player_card IS 'Карты у игрока в руках';


--
-- TOC entry 204 (class 1259 OID 41990)
-- Name: playing_card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.playing_card (
    id_card integer NOT NULL,
    id_suit integer,
    card_value integer NOT NULL
);


--
-- TOC entry 3161 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE playing_card; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.playing_card IS 'Игральная карта';


--
-- TOC entry 202 (class 1259 OID 41979)
-- Name: suit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suit (
    id_suit integer NOT NULL,
    name_suit character varying NOT NULL
);


--
-- TOC entry 3162 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE suit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.suit IS 'Масть карт';


--
-- TOC entry 212 (class 1259 OID 42254)
-- Name: cards_in_hands; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cards_in_hands AS
 SELECT player.id_game,
    player.id_user,
    player.id_player,
    player.number_player,
    player_card.id_card,
    playing_card.id_suit,
    playing_card.card_value,
    suit.name_suit
   FROM (((public.player
     JOIN public.player_card ON ((player.id_player = player_card.id_player)))
     JOIN public.playing_card ON ((playing_card.id_card = player_card.id_card)))
     JOIN public.suit ON ((suit.id_suit = playing_card.id_suit)));


--
-- TOC entry 3163 (class 0 OID 0)
-- Dependencies: 212
-- Name: VIEW cards_in_hands; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.cards_in_hands IS 'Карты у игрока';


--
-- TOC entry 206 (class 1259 OID 42069)
-- Name: game; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game (
    id_game uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    trump_card integer,
    whose_turn integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    number_turn integer DEFAULT 1 NOT NULL,
    attack boolean DEFAULT true NOT NULL
);


--
-- TOC entry 3164 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN game.whose_turn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game.whose_turn IS 'Чей ход:
null - никто (игра не начата, игра окончена и т.п.)
1- первый игрок
2- второй игрок';


--
-- TOC entry 3165 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN game.number_turn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game.number_turn IS 'Номер хода (Может удалить?)';


--
-- TOC entry 3166 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN game.attack; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game.attack IS 'Идёт нападение или защита?';


--
-- TOC entry 209 (class 1259 OID 42195)
-- Name: game_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_table (
    id_game_table uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_player uuid,
    numb_card integer DEFAULT 1 NOT NULL,
    id_card integer
);


--
-- TOC entry 3167 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE game_table; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.game_table IS 'Игровой стол';


--
-- TOC entry 3168 (class 0 OID 0)
-- Dependencies: 209
-- Name: COLUMN game_table.id_player; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_table.id_player IS 'ID игрока';


--
-- TOC entry 3169 (class 0 OID 0)
-- Dependencies: 209
-- Name: COLUMN game_table.numb_card; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_table.numb_card IS 'Номер карты/места на игровом столе';


--
-- TOC entry 3170 (class 0 OID 0)
-- Dependencies: 209
-- Name: COLUMN game_table.id_card; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.game_table.id_card IS 'Игровая карта';


--
-- TOC entry 213 (class 1259 OID 50431)
-- Name: cards_in_table; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cards_in_table AS
 SELECT game_table.id_game_table,
    game.id_game,
    game.number_turn,
    player.id_user,
    player.id_player,
    player.number_player,
    game_table.numb_card,
    playing_card.id_card,
    playing_card.id_suit,
    playing_card.card_value,
        CASE
            WHEN (game.whose_turn = player.number_player) THEN 1
            ELSE 0
        END AS attack
   FROM (((public.game
     JOIN public.player ON ((game.id_game = player.id_game)))
     JOIN public.game_table ON ((game_table.id_player = player.id_player)))
     JOIN public.playing_card ON ((game_table.id_card = playing_card.id_card)));


--
-- TOC entry 3171 (class 0 OID 0)
-- Dependencies: 213
-- Name: VIEW cards_in_table; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.cards_in_table IS 'Все карты на столе';


--
-- TOC entry 211 (class 1259 OID 42214)
-- Name: game_card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_card (
    id_game_card integer NOT NULL,
    id_game uuid,
    id_card integer
);


--
-- TOC entry 3172 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE game_card; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.game_card IS 'Перемешанная колода карт';


--
-- TOC entry 210 (class 1259 OID 42212)
-- Name: game_card_id_game_card_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_card_id_game_card_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3173 (class 0 OID 0)
-- Dependencies: 210
-- Name: game_card_id_game_card_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_card_id_game_card_seq OWNED BY public.game_card.id_game_card;


--
-- TOC entry 214 (class 1259 OID 50448)
-- Name: playing_card_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.playing_card_view AS
 SELECT playing_card.id_card,
    playing_card.id_suit,
    playing_card.card_value,
    suit.name_suit
   FROM (public.playing_card
     JOIN public.suit ON ((suit.id_suit = playing_card.id_suit)));


--
-- TOC entry 205 (class 1259 OID 42015)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id_user uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name_user character varying NOT NULL,
    email character varying NOT NULL,
    password character varying NOT NULL,
    wins numeric DEFAULT 0 NOT NULL
);


--
-- TOC entry 3174 (class 0 OID 0)
-- Dependencies: 205
-- Name: COLUMN users.wins; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.wins IS 'Количество побед';


--
-- TOC entry 215 (class 1259 OID 50459)
-- Name: game_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.game_view AS
 SELECT game.id_game,
    game.whose_turn,
    game.attack,
    game.trump_card,
    player.id_user,
    users.name_user,
    player.number_player,
    player.robot,
    player.id_player,
    game.created_at,
    playing_card_view.id_suit AS trump_id_suit,
    playing_card_view.card_value AS trump_card_value,
    playing_card_view.name_suit AS trump_name_suit,
    ( SELECT count(*) AS count
           FROM public.game_card
          WHERE (game_card.id_game = game.id_game)) AS count_cards
   FROM (((public.game
     JOIN public.player ON ((game.id_game = player.id_game)))
     JOIN public.users ON ((player.id_user = users.id_user)))
     JOIN public.playing_card_view ON ((playing_card_view.id_card = game.trump_card)));


--
-- TOC entry 217 (class 1259 OID 58657)
-- Name: number_tmp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.number_tmp (
    id_game uuid,
    id_user uuid,
    id_player uuid,
    number_player integer,
    id_card integer,
    id_suit integer,
    card_value integer,
    name_suit character varying
);


--
-- TOC entry 203 (class 1259 OID 41988)
-- Name: playing_card_id_card_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.playing_card_id_card_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3175 (class 0 OID 0)
-- Dependencies: 203
-- Name: playing_card_id_card_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.playing_card_id_card_seq OWNED BY public.playing_card.id_card;


--
-- TOC entry 216 (class 1259 OID 50481)
-- Name: score; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.score (
    id_score uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_game uuid NOT NULL,
    id_user uuid NOT NULL
);


--
-- TOC entry 201 (class 1259 OID 41977)
-- Name: suit_id_suit_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suit_id_suit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3176 (class 0 OID 0)
-- Dependencies: 201
-- Name: suit_id_suit_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suit_id_suit_seq OWNED BY public.suit.id_suit;


--
-- TOC entry 2955 (class 2604 OID 42217)
-- Name: game_card id_game_card; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_card ALTER COLUMN id_game_card SET DEFAULT nextval('public.game_card_id_game_card_seq'::regclass);


--
-- TOC entry 2941 (class 2604 OID 41993)
-- Name: playing_card id_card; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playing_card ALTER COLUMN id_card SET DEFAULT nextval('public.playing_card_id_card_seq'::regclass);


--
-- TOC entry 2940 (class 2604 OID 41982)
-- Name: suit id_suit; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suit ALTER COLUMN id_suit SET DEFAULT nextval('public.suit_id_suit_seq'::regclass);


--
-- TOC entry 3130 (class 0 OID 42069)
-- Dependencies: 206
-- Data for Name: game; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.game (id_game, trump_card, whose_turn, created_at, updated_at, number_turn, attack) FROM stdin;
afca9447-b263-4745-b650-ffa340b93f32	28	\N	2021-11-04 17:10:35.7236	2021-11-04 17:16:38.83982	15	t
21538f1c-2e33-4a34-93bc-9e3cd4565661	27	\N	2021-11-21 15:19:33.64803	2021-11-21 17:18:30.075802	11	t
6785ecae-f3e2-4e67-8b8e-74f3c9d8f646	7	\N	2021-11-21 17:18:34.581609	2021-12-04 15:52:32.437588	16	t
97501256-cb51-4997-8161-b4ddf4010798	3	\N	2021-11-04 16:43:18.06918	2021-11-04 17:10:21.504537	16	t
\.


--
-- TOC entry 3135 (class 0 OID 42214)
-- Dependencies: 211
-- Data for Name: game_card; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.game_card (id_game_card, id_game, id_card) FROM stdin;
\.


--
-- TOC entry 3133 (class 0 OID 42195)
-- Dependencies: 209
-- Data for Name: game_table; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.game_table (id_game_table, id_player, numb_card, id_card) FROM stdin;
6c1fbf4f-d159-4bae-989e-794c3f26acad	7604deec-66ac-446a-abd4-ecdc86042293	1	5
f01708dd-890e-4f0d-ab0f-19d05d7cc70f	34b9f830-5155-4998-aa1c-d4f4773fcf20	1	36
4fc09ec5-da7c-41c9-b92b-eb038a18f7d0	7604deec-66ac-446a-abd4-ecdc86042293	2	14
e3c2a37b-baed-4f3f-9e91-969acc5f302a	7604deec-66ac-446a-abd4-ecdc86042293	3	23
d84e6881-e3cd-49d3-9802-a81c81637a56	34b9f830-5155-4998-aa1c-d4f4773fcf20	2	34
649070b8-b5bd-4156-8f0f-dfbaffc9c05e	34b9f830-5155-4998-aa1c-d4f4773fcf20	3	35
21165104-a8c5-43c6-8b44-53447a567795	cc4d5b04-f90a-426a-a420-79bb513d313c	1	29
9864627f-997a-41ad-9b43-09f7069ec67e	0fb83157-efad-43d8-8e0d-974202606be0	1	32
\.


--
-- TOC entry 3137 (class 0 OID 58657)
-- Dependencies: 217
-- Data for Name: number_tmp; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.number_tmp (id_game, id_user, id_player, number_player, id_card, id_suit, card_value, name_suit) FROM stdin;
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	293c4560-c1fe-461a-a51c-aa87557d517f	99fad2b2-3ea1-4ba9-a401-26a8bbd6fec4	1	9	1	14	Пики
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	13	2	9	Крести
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	22	3	9	Буби
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	31	4	9	Черви
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	26	3	13	Буби
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	35	4	13	Черви
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	8	1	13	Пики
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	23	3	10	Буби
2e667e7d-3d27-4f2c-887b-d4c4a7f778d6	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f691f7c0-ac36-4ae9-8b9a-ecbbdfc09e20	2	32	4	10	Черви
\.


--
-- TOC entry 3131 (class 0 OID 42161)
-- Dependencies: 207
-- Data for Name: player; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player (id_player, id_game, id_user, robot, number_player) FROM stdin;
c9845e22-6913-4fcf-a298-762f768c2239	97501256-cb51-4997-8161-b4ddf4010798	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f	1
8a80d37a-200e-406d-84b2-e3eeba4576f3	97501256-cb51-4997-8161-b4ddf4010798	293c4560-c1fe-461a-a51c-aa87557d517f	f	2
7604deec-66ac-446a-abd4-ecdc86042293	afca9447-b263-4745-b650-ffa340b93f32	293c4560-c1fe-461a-a51c-aa87557d517f	f	1
34b9f830-5155-4998-aa1c-d4f4773fcf20	afca9447-b263-4745-b650-ffa340b93f32	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f	2
8ba546ea-8854-4edf-960b-b40f8aa4e6bd	21538f1c-2e33-4a34-93bc-9e3cd4565661	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f	1
df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	21538f1c-2e33-4a34-93bc-9e3cd4565661	293c4560-c1fe-461a-a51c-aa87557d517f	f	2
0fb83157-efad-43d8-8e0d-974202606be0	6785ecae-f3e2-4e67-8b8e-74f3c9d8f646	293c4560-c1fe-461a-a51c-aa87557d517f	f	1
cc4d5b04-f90a-426a-a420-79bb513d313c	6785ecae-f3e2-4e67-8b8e-74f3c9d8f646	6409f987-1cdc-4c64-8f10-93c4a33dcf79	f	2
\.


--
-- TOC entry 3132 (class 0 OID 42179)
-- Dependencies: 208
-- Data for Name: player_card; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_card (id_player_card, id_player, id_card) FROM stdin;
e034baa0-2c5e-4435-87ad-f8798ec5a114	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	36
ce313b3d-d515-42da-a327-57b031120ca7	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	27
97c9f160-b607-458b-9021-169d81610014	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	18
e70b641d-7b74-473e-a0d1-0f211f78b6a0	7604deec-66ac-446a-abd4-ecdc86042293	32
4751415a-7ea0-4fc7-a59d-6e766b26fbfe	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	9
ef1888c4-5bba-441a-9eac-acd11da5874a	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	34
227df70c-829b-4217-b3a4-ba089bc0b411	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	16
09ed7e22-2be1-435b-82a7-a2080f5997ac	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	29
6c057b54-76d0-44f0-885e-e779ce05634f	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	1
efa079cb-718e-463f-b709-f296e678860c	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	8
5eb33165-6693-4bcd-9077-b0d2be7c021d	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	35
8b792154-3fac-49ca-8e09-57817a6dde1e	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	20
32dba188-3a29-462a-8463-095f1c105640	df2c6a7c-a70e-4de3-9e1e-6db0ab527a42	26
\.


--
-- TOC entry 3128 (class 0 OID 41990)
-- Dependencies: 204
-- Data for Name: playing_card; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.playing_card (id_card, id_suit, card_value) FROM stdin;
1	1	6
2	1	7
3	1	8
4	1	9
5	1	10
6	1	11
7	1	12
8	1	13
9	1	14
10	2	6
11	2	7
12	2	8
13	2	9
14	2	10
15	2	11
16	2	12
17	2	13
18	2	14
19	3	6
20	3	7
21	3	8
22	3	9
23	3	10
24	3	11
25	3	12
26	3	13
27	3	14
28	4	6
29	4	7
30	4	8
31	4	9
32	4	10
33	4	11
34	4	12
35	4	13
36	4	14
\.


--
-- TOC entry 3136 (class 0 OID 50481)
-- Dependencies: 216
-- Data for Name: score; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.score (id_score, id_game, id_user) FROM stdin;
60bf5a12-93e1-4d5d-9877-c5e4095d234c	97501256-cb51-4997-8161-b4ddf4010798	6409f987-1cdc-4c64-8f10-93c4a33dcf79
52fceea9-70a2-4f6d-bc78-3d917802718b	afca9447-b263-4745-b650-ffa340b93f32	6409f987-1cdc-4c64-8f10-93c4a33dcf79
3da132e1-6748-48a5-8115-74b8b647ada5	21538f1c-2e33-4a34-93bc-9e3cd4565661	6409f987-1cdc-4c64-8f10-93c4a33dcf79
0a247f6f-8b80-47be-a9db-45390e383e88	6785ecae-f3e2-4e67-8b8e-74f3c9d8f646	293c4560-c1fe-461a-a51c-aa87557d517f
2a849dbf-c375-418c-85c7-063f1c53b9fe	6785ecae-f3e2-4e67-8b8e-74f3c9d8f646	6409f987-1cdc-4c64-8f10-93c4a33dcf79
\.


--
-- TOC entry 3126 (class 0 OID 41979)
-- Dependencies: 202
-- Data for Name: suit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suit (id_suit, name_suit) FROM stdin;
1	Пики
2	Крести
3	Буби
4	Черви
\.


--
-- TOC entry 3129 (class 0 OID 42015)
-- Dependencies: 205
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id_user, name_user, email, password, wins) FROM stdin;
30910ade-871e-4b96-bc91-abfb8bdcd342	User1	email@testdomain.com	$2b$10$YRIznazrgBoJyvADxlpa.uI1XgnQ8WzNT0.88z3r.wTi6aGG9Vk9y	0
293c4560-c1fe-461a-a51c-aa87557d517f	Игрок 1	seven77@yandex.ru	$2b$10$YRIznazrgBoJyvADxlpa.uI1XgnQ8WzNT0.88z3r.wTi6aGG9Vk9y	0
6409f987-1cdc-4c64-8f10-93c4a33dcf79	Gamer 2	slsinitsin@gmail.com	$2b$10$YRIznazrgBoJyvADxlpa.uI1XgnQ8WzNT0.88z3r.wTi6aGG9Vk9y	0
b8b37da5-d9bd-4037-b8d7-378a9f22c722	qqq	qqq@qqq.ru	$2b$10$OVGV/wRUSTeTjEuOPruvrevoNZ0y62VoE0QTsXpor8Sqjh1Z7kdAu	0
\.


--
-- TOC entry 3177 (class 0 OID 0)
-- Dependencies: 210
-- Name: game_card_id_game_card_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.game_card_id_game_card_seq', 2556, true);


--
-- TOC entry 3178 (class 0 OID 0)
-- Dependencies: 203
-- Name: playing_card_id_card_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.playing_card_id_card_seq', 36, true);


--
-- TOC entry 3179 (class 0 OID 0)
-- Dependencies: 201
-- Name: suit_id_suit_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.suit_id_suit_seq', 4, true);


--
-- TOC entry 2960 (class 2606 OID 41995)
-- Name: playing_card card_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playing_card
    ADD CONSTRAINT card_pkey PRIMARY KEY (id_card);


--
-- TOC entry 2962 (class 2606 OID 42025)
-- Name: users email_cu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT email_cu UNIQUE (email);


--
-- TOC entry 2976 (class 2606 OID 42219)
-- Name: game_card id_game_card_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_card
    ADD CONSTRAINT id_game_card_pkey PRIMARY KEY (id_game_card);


--
-- TOC entry 2968 (class 2606 OID 42076)
-- Name: game id_game_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game
    ADD CONSTRAINT id_game_pkey PRIMARY KEY (id_game);


--
-- TOC entry 2974 (class 2606 OID 42201)
-- Name: game_table id_game_table; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_table
    ADD CONSTRAINT id_game_table PRIMARY KEY (id_game_table);


--
-- TOC entry 2972 (class 2606 OID 42184)
-- Name: player_card id_player_card_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_card
    ADD CONSTRAINT id_player_card_pkey PRIMARY KEY (id_player_card);


--
-- TOC entry 2970 (class 2606 OID 42168)
-- Name: player id_player_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT id_player_pkey PRIMARY KEY (id_player);


--
-- TOC entry 2964 (class 2606 OID 42023)
-- Name: users id_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT id_user_pkey PRIMARY KEY (id_user);


--
-- TOC entry 2966 (class 2606 OID 42027)
-- Name: users name_user_cu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT name_user_cu UNIQUE (name_user);


--
-- TOC entry 2978 (class 2606 OID 50486)
-- Name: score scores_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score
    ADD CONSTRAINT scores_pk PRIMARY KEY (id_score);


--
-- TOC entry 2958 (class 2606 OID 41987)
-- Name: suit suit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suit
    ADD CONSTRAINT suit_pkey PRIMARY KEY (id_suit);


--
-- TOC entry 2988 (class 2606 OID 42225)
-- Name: game_card game_card_id_card_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_card
    ADD CONSTRAINT game_card_id_card_fkey FOREIGN KEY (id_card) REFERENCES public.playing_card(id_card);


--
-- TOC entry 2987 (class 2606 OID 42220)
-- Name: game_card game_card_id_game_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_card
    ADD CONSTRAINT game_card_id_game_fkey FOREIGN KEY (id_game) REFERENCES public.game(id_game) ON DELETE CASCADE;


--
-- TOC entry 2986 (class 2606 OID 42207)
-- Name: game_table game_table_id_card_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_table
    ADD CONSTRAINT game_table_id_card_fkey FOREIGN KEY (id_card) REFERENCES public.playing_card(id_card);


--
-- TOC entry 2985 (class 2606 OID 42202)
-- Name: game_table game_table_id_player_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_table
    ADD CONSTRAINT game_table_id_player_fkey FOREIGN KEY (id_player) REFERENCES public.player(id_player) ON DELETE CASCADE;


--
-- TOC entry 2980 (class 2606 OID 42077)
-- Name: game game_trump_card_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game
    ADD CONSTRAINT game_trump_card_fkey FOREIGN KEY (trump_card) REFERENCES public.playing_card(id_card);


--
-- TOC entry 2984 (class 2606 OID 42190)
-- Name: player_card player_card_id_card_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_card
    ADD CONSTRAINT player_card_id_card_fkey FOREIGN KEY (id_card) REFERENCES public.playing_card(id_card);


--
-- TOC entry 2983 (class 2606 OID 42185)
-- Name: player_card player_card_id_player_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_card
    ADD CONSTRAINT player_card_id_player_fkey FOREIGN KEY (id_player) REFERENCES public.player(id_player) ON DELETE CASCADE;


--
-- TOC entry 2981 (class 2606 OID 42169)
-- Name: player player_id_game_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_id_game_fkey FOREIGN KEY (id_game) REFERENCES public.game(id_game) ON DELETE CASCADE;


--
-- TOC entry 2982 (class 2606 OID 42174)
-- Name: player player_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- TOC entry 2979 (class 2606 OID 41996)
-- Name: playing_card playing_card_id_suit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playing_card
    ADD CONSTRAINT playing_card_id_suit_fkey FOREIGN KEY (id_suit) REFERENCES public.suit(id_suit) ON DELETE CASCADE;


--
-- TOC entry 2989 (class 2606 OID 50487)
-- Name: score scores_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score
    ADD CONSTRAINT scores_fk FOREIGN KEY (id_game) REFERENCES public.game(id_game) ON DELETE CASCADE;


--
-- TOC entry 2990 (class 2606 OID 50492)
-- Name: score scores_fk_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score
    ADD CONSTRAINT scores_fk_user FOREIGN KEY (id_user) REFERENCES public.users(id_user);


-- Completed on 2022-01-02 12:55:34

--
-- PostgreSQL database dump complete
--

