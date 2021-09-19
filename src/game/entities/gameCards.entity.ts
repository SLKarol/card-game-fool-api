import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'game_card', synchronize: false })
export class GameCardsEntity {
  @PrimaryGeneratedColumn('uuid', { name: 'id_game_card' })
  idGameCard: string;

  @Column({ unique: true, name: 'id_game' })
  idGame: string;

  @Column({ name: 'id_card' })
  idCard: string;
}
