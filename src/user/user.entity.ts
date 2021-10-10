import {
  BeforeInsert,
  Column,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { hash, genSalt } from 'bcrypt';
import { ScoreEntity } from '@app/game/entities/score.entity';

@Entity({ name: 'users' })
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id_user: string;

  @Column({ unique: true })
  name_user: string;

  @Column()
  email: string;

  @Column()
  password: string;

  @Column({ type: 'numeric' })
  wins: number;

  @OneToMany(() => ScoreEntity, (score) => score.game)
  scores: ScoreEntity[];

  @BeforeInsert()
  async hashPassword() {
    const salt = await genSalt(10);
    this.password = await hash(this.password, salt);
  }
}
