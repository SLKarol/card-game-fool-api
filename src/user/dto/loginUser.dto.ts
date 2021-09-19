import { UserDto } from './user.dto';

export type LoginUserDto = Pick<UserDto, 'email' | 'password'>;
