import { CanActivate, Injectable } from '@nestjs/common';
import { verify } from 'jsonwebtoken';
import { Observable } from 'rxjs';

// todo Доделать и применить с UserGuards - который тоже нужно сделать
@Injectable()
export class WsGuard implements CanActivate {
  canActivate(
    context: any,
  ): boolean | any | Promise<boolean | any> | Observable<boolean | any> {
    try {
      const bearerToken =
        context.args[0].handshake.headers.authorization.split(' ')[1];
      const decoded = verify(bearerToken, process.env.JWT_SECRET) as any;
      return decoded?.id_user;
    } catch (ex) {
      console.log(ex);
      return false;
    }
  }
}
