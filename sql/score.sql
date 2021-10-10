CREATE TABLE scores (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  id_game uuid NOT NULL,
  id_user uuid NOT NULL,
  CONSTRAINT scores_pk PRIMARY KEY (id),
  CONSTRAINT scores_fk FOREIGN KEY (id_game) REFERENCES game(id_game) ON
  DELETE
    CASCADE,
    CONSTRAINT scores_fk_user FOREIGN KEY (id_user) REFERENCES users(id_user)
);