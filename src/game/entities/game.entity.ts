import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

import { ScoreEntity } from './score.entity';

@Entity({ name: 'game' })
export class GameEntity {
  @PrimaryGeneratedColumn('uuid')
  id_game: string;

  @Column({ unique: true, name: 'trump_card' })
  trumpCard: number;

  @Column({ name: 'whose_turn' })
  whoseTurn: number;

  @Column({ name: 'number_turn' })
  numberTurn: number;

  @Column()
  attack: boolean;

  @Column({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    name: 'created_at',
  })
  createdAt: Date;

  @Column({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
    name: 'updated_at',
  })
  updatedAt: Date;

  @OneToMany(() => ScoreEntity, (score) => score.game)
  scores: ScoreEntity[];
}
