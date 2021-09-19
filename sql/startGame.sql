CREATE
OR REPLACE FUNCTION start_game(player1 uuid, player2 uuid DEFAULT NULL) RETURNS uuid LANGUAGE 'plpgsql' AS $$
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

COMMENT ON FUNCTION start_game(uuid, uuid) IS 'Начинает игру с параметрами:
* ID первого игрока
* ID второго игрока
';