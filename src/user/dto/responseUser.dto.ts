import { UserEntity } from '../user.entity';

interface UserInterface
  extends Omit<
    UserEntity,
    'id_user' | 'password' | 'hashPassword' | 'name_user'
  > {
  token: string;
  username: string;
}

export interface ResponseUserInterface {
  user: UserInterface;
}
