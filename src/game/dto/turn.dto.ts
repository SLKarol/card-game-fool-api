import { IsNotEmpty, IsPositive } from 'class-validator';

export class TurnGameDto {
  @IsNotEmpty()
  gameId: string;

  @IsPositive()
  cardId: number;
}
