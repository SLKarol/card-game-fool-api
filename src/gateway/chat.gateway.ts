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
    console.log('connect user :>> ', user);

    const { id_user, name_user } = user;
    socket.data.user = { id_user, name_user };
  }

  @SubscribeMessage('send_message')
  async listenForMessages(
    @MessageBody() data: string,
    @ConnectedSocket() socket: Socket,
  ) {
    // const gamerId = await this.chatService.getUserIdFromSocket(client);
    console.log('data :>> ', data);
    console.log('gamer :>> ', socket.data);
    socket.send('Some from server');
    socket.emit('receive_message', 'Ho-ho!');
    return data;
  }

  @SubscribeMessage('join_chat')
  async joinGameChat(
    @MessageBody() data: { gameId: string },
    @ConnectedSocket() socket: Socket,
  ) {
    const { name_user: nameUser } = socket.data.user;
    const { gameId } = data;
    this.chatService.createGameChat(socket, gameId);
    socket.join(gameId);
    socket
      .in(gameId)
      .emit('chat', { message: `${nameUser} вошёл в игру`, sender: 'system' });
  }
}
