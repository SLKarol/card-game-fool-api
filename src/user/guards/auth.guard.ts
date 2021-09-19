import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

import { ExpressRequest } from '@app/types/expressRequest.interface';

// @Injectable()
// export class AuthGuard implements CanActivate {
//   canActivate(context: ExecutionContext): boolean {
//     const request = context.switchToHttp().getRequest<ExpressRequest>();
//     if (request.user) return true;

//     throw new HttpException('Not authorized', HttpStatus.UNAUTHORIZED);
//   }
// }

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
