import { IsNotEmpty } from 'class-validator';

export class CreateGameDto {
  @IsNotEmpty()
  readonly opponent: string;
}

export interface InfoNewGame {
  game: { id: string };
}

/**
 * Открытая игра
 */
export interface OpenGameDto {
  idGame: string;
  nameUser: string;
  createdAt: string;
}

export interface GameOver {
  game: { id: string; gameReady: boolean };
}
