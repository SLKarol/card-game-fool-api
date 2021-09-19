import { Module } from '@nestjs/common';

import { UserModule } from '@app/user/user.module';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';

@Module({
  imports: [UserModule],
  providers: [ChatService, ChatGateway],
})
export class ChatModule {}
