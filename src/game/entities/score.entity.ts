import { ManyToOne, Entity, PrimaryGeneratedColumn, JoinColumn } from 'typeorm';

import { GameEntity } from './game.entity';
import { UserEntity } from '@app/user/user.entity';

@Entity({ name: 'score' })
export class ScoreEntity {
  @PrimaryGeneratedColumn('uuid', { name: 'id_score' })
  id: string;

  @ManyToOne(() => GameEntity, (game) => game.scores, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_game' })
  game: GameEntity;

  @ManyToOne(() => UserEntity, (user) => user.scores)
  @JoinColumn({ name: 'id_user' })
  user: UserEntity;
}
