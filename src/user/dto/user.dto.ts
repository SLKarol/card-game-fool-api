import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class UserDto {
  @IsString()
  readonly id_user: string;

  @IsNotEmpty()
  @IsString({ message: 'Это же строка должна быть' })
  readonly name_user: string;

  @IsNotEmpty()
  @IsEmail({}, { message: 'Должен быть электронный адрес' })
  readonly email: string;

  @IsNotEmpty()
  readonly password: string;

  wins: number;
}

export class MainUserDto {
  readonly user: UserDto;
}
