import { BeforeInsert, Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { hash, genSalt } from 'bcrypt';

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

  @BeforeInsert()
  async hashPassword() {
    const salt = await genSalt(10);
    this.password = await hash(this.password, salt);
  }
}
