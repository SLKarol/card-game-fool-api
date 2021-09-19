import {
  Controller,
  Post,
  Body,
  UsePipes,
  Get,
  UseGuards,
} from '@nestjs/common';

import { UserService } from './user.service';
import { User } from './decorators/user.decorator';
import { JwtAuthGuard } from './guards/auth.guard';
import { BackendValidationPipe } from '@app/shared/pipes/backendValidation.pipe';
import { CreateUserDto } from './dto/ceateUser.dto';
import { ResponseUserInterface } from './dto/responseUser.dto';
import { LoginUserDto } from './dto/loginUser.dto';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('users')
  @UsePipes(new BackendValidationPipe())
  async createUser(
    @Body('user') createUserDto: CreateUserDto,
  ): Promise<ResponseUserInterface> {
    const user = await this.userService.createUser(createUserDto);
    return this.userService.buildUserResponse(user);
  }

  @Post('users/login')
  @UsePipes(new BackendValidationPipe())
  async login(
    @Body('user') loginDto: LoginUserDto,
  ): Promise<ResponseUserInterface> {
    const user = await this.userService.login(loginDto);
    return this.userService.buildUserResponse(user);
  }

  @Get('user')
  @UseGuards(JwtAuthGuard)
  async currentUser(
    @User('id_user') currentUserId: string,
  ): Promise<ResponseUserInterface> {
    const user = await this.userService.findUserById(currentUserId);
    return this.userService.buildUserResponse(user);
  }

  @Get('user/opponents')
  @UseGuards(JwtAuthGuard)
  async opponentsUser(
    @User('id_user') currentUserId: string,
  ): Promise<{ users: string[] }> {
    const opponents = await this.userService.getOpponents(currentUserId);
    return this.userService.buildListOpponents(opponents);
  }
}
