import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';
import { WsException } from '@nestjs/websockets';

import { UserService } from '@app/user/user.service';
import { UserEntity } from '@app/user/user.entity';

@Injectable()
export class ChatService {
  constructor(private userService: UserService) {}

  async getUserFromSocket(socket: Socket): Promise<UserEntity> {
    try {
      const bearerToken = socket.handshake.auth.token;
      const idUser = await this.userService.getUserIdFromAuthenticationToken(
        bearerToken,
      );
      if (!idUser) {
        throw new WsException('Invalid credentials.');
      }
      const user = await this.userService.findUserById(idUser);
      return user;
    } catch (e) {
      throw new WsException('Invalid credentials.');
    }
  }

  createGameChat(socket: Socket, chatId: string) {
    if (!socket.rooms.has(chatId)) {
      socket.rooms.add(chatId);
    }
  }
}
