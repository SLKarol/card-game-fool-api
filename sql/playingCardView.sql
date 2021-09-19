CREATE
OR REPLACE VIEW playing_card_view AS
SELECT
  playing_card.id_card,
  playing_card.id_suit,
  playing_card.card_value,
  suit.name_suit
FROM
  playing_card
  JOIN suit ON suit.id_suit = playing_card.id_suit;