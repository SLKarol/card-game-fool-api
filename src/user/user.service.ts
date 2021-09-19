import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { compare } from 'bcrypt';

import { LoginUserDto } from './dto/loginUser.dto';
import { ResponseUserInterface } from './dto/responseUser.dto';

import { Not, Repository } from 'typeorm';
import { UserEntity } from './user.entity';
import { CreateUserDto } from './dto/ceateUser.dto';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
    private configService: ConfigService,
    private readonly jwtService: JwtService,
  ) {}

  async createUser(createUserDto: CreateUserDto): Promise<UserEntity> {
    const errorResponse = {
      errors: {},
    };
    const userByEmail = await this.userRepository.findOne({
      email: createUserDto.email,
    });
    const userByUsername = await this.userRepository.findOne({
      name_user: createUserDto.username,
    });

    if (userByEmail) {
      errorResponse.errors['email'] = 'has already been taken';
    }

    if (userByUsername) {
      errorResponse.errors['username'] = 'has already been taken';
    }
    if (userByEmail || userByUsername) {
      throw new HttpException(errorResponse, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    const newUser = new UserEntity();
    const { username, ...createDto } = createUserDto;
    Object.assign(newUser, { ...createDto, name_user: username });
    return this.userRepository.save(newUser);
  }

  async buildUserResponse(user: UserEntity): Promise<ResponseUserInterface> {
    const userReport = Object.assign({}, user);
    delete userReport.id_user;
    delete userReport.password;
    const { name_user, ...userData } = userReport;
    return {
      user: {
        username: name_user,
        ...userData,
        token: await this.generateJwt(user),
      },
    };
  }

  private async generateJwt(user: UserEntity): Promise<string> {
    const { id_user } = user;
    return await this.jwtService.signAsync({ id_user });
  }

  async login(loginUserDto: LoginUserDto): Promise<UserEntity> {
    const errorResponse = {
      errors: {
        'email or password': 'is invalid',
      },
    };
    const user = await this.userRepository.findOne({
      where: { email: loginUserDto.email },
      select: ['id_user', 'name_user', 'email', 'password', 'wins'],
    });

    if (!user) {
      throw new HttpException(errorResponse, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    const isPasswordCorrect = await compare(
      loginUserDto.password,
      user.password,
    );

    if (!isPasswordCorrect) {
      throw new HttpException(errorResponse, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    delete user.password;
    return user;
  }

  async findUserById(id: string) {
    return this.userRepository.findOne({ id_user: id });
  }

  /**
   * Получить список оппонентов для пользователя
   */
  async getOpponents(idUser: string): Promise<UserEntity[]> {
    const opponents = await this.userRepository.find({
      where: { id_user: Not(idUser) },
      order: { name_user: 'ASC' },
      select: ['name_user'],
    });
    return opponents;
  }

  buildListOpponents(listUsers: UserEntity[]): { users: string[] } {
    const users = listUsers.map((user) => user.name_user);
    return { users };
  }

  async findUserByName(name: string) {
    return this.userRepository.findOne({ name_user: name });
  }

  getUserIdFromAuthenticationToken(token: string): string | undefined {
    const data: { id_user: string } = this.jwtService.verify(token);
    return data?.id_user;
  }
}
