import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({ cors: true })
export class ChatGateway implements OnGatewayConnection {
  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  async handleConnection(socket: Socket) {
    const user = await this.chatService.getUserFromSocket(socket);
    const { id_user, name_user } = user;
    socket.data.user = { id_user, name_user };
  }

  @SubscribeMessage('send_message')
  async listenForMessages(
    @MessageBody() data: { gameId: string; message: string },
    @ConnectedSocket() socket: Socket,
  ) {
    socket.in(data.gameId).emit('chat', {
      message: data.message,
      sender: 'opponent',
      dateTime: new Date().toISOString(),
    });
    return data;
  }

  @SubscribeMessage('join_game')
  async joinGameChat(
    @MessageBody() data: { gameId: string },
    @ConnectedSocket() socket: Socket,
  ) {
    const { user } = socket.data;
    if (!user) return;
    const { name_user } = user;
    const { gameId } = data;
    this.chatService.createGameChat(socket, gameId);
    await socket.join(gameId);
    socket.in(gameId).emit('chat', {
      message: `${name_user} вошёл в игру`,
      sender: 'system',
      dateTime: new Date().toISOString(),
    });
  }

  @SubscribeMessage('leave_game')
  async leaveGameChat(
    @MessageBody() data: { gameId: string },
    @ConnectedSocket() socket: Socket,
  ) {
    const { name_user: nameUser } = socket.data.user;
    const { gameId } = data;
    this.chatService.createGameChat(socket, gameId);
    await socket.leave(gameId);
    socket.in(gameId).emit('chat', {
      message: `${nameUser} вышел из игры`,
      sender: 'system',
      dateTime: new Date().toISOString(),
    });
  }
}
